#!/usr/bin/env bash
# Provision the harness's two checkers from the npm registry only — no
# firewalled downloads (Adoptium/GitHub/Maven are not required and are
# typically blocked in sandboxes). Run once per session; node_modules is
# git-ignored. The TLC jar (tools/tlc/tla2tools.jar) and the Alloy jar
# (tools/alloy/alloy.jar) are committed; to replace the Alloy jar, save
# org.alloytools.alloy.dist.jar from the AlloyTools releases there.
set -euo pipefail
cd "$(dirname "$0")"

echo "Installing tla-checker (TLA+ WASM) into the repo node_modules..."
npm install --no-audit --no-fund

# The JRE 17 goes on the native /tmp FS, NOT the mounted repo: unpacking the
# JRE into the mount drops libjli.so and the launcher dies with exit 127.
if [ "$(uname)" = Darwin ]; then
  # The npm JRE is Linux-only. check.mjs finds a JDK 17+ via JAVA_HOME,
  # /usr/libexec/java_home or Homebrew; install one with: brew install openjdk@17
  JAVA="$(/usr/libexec/java_home -v 17+ 2>/dev/null || true)/bin/java"
  [ -x "$JAVA" ] || JAVA="$(brew --prefix openjdk@17 2>/dev/null || true)/bin/java"
  [ -x "$JAVA" ] || echo "macOS: no JDK 17+ found — run: brew install openjdk@17"
else
JRE_DIR=/tmp/javajre
echo "Installing javajre-linux-64 (JRE 17) into $JRE_DIR ..."
mkdir -p "$JRE_DIR"
( cd "$JRE_DIR" && npm install --no-audit --no-fund javajre-linux-64@17.0.8 )
JAVA="$JRE_DIR/node_modules/javajre-linux-64/jre/bin/java"
chmod +x "$JAVA" 2>/dev/null || true
fi
echo
echo "TLA+ checker : $(ls node_modules/tla-checker/tla_checker_bg.wasm >/dev/null 2>&1 && echo OK || echo MISSING)"
echo "JRE 17       : $("$JAVA" -version 2>&1 | head -1)"
echo "TLC jar      : $(ls ../tlc/tla2tools.jar >/dev/null 2>&1 && echo OK || echo 'MISSING — tools/tlc/tla2tools.jar is committed')"
echo "Alloy jar    : $(ls ../alloy/alloy.jar >/dev/null 2>&1 && echo OK || echo 'MISSING — save org.alloytools.alloy.dist.jar from the AlloyTools releases as tools/alloy/alloy.jar')"
# TLAPS (tlapm), the TLA+ Proof System — the 1.6.0 rolling pre-release, pinned by
# checksum (unit `tooling: TLAPS installed and wired`, Scott 2026-11-10: a named
# exception to "only stable versions", since the last stable build, 1.5.0, is an
# Intel-only installer). The release is rolling: the tag may be moved to newer
# bytes, and bytes that do not match the checksum are never installed. Pinned:
# tlaplus/tlapm tag 1.6.0-pre at commit bf665f4d162c1ae5010ca878578cd50a810ec205
# (`tlapm --version` prints bf665f4; unit `tooling: the TLAPS pin moves to the
# release's current build, and our own copy is kept`, Scott 2026-11-16). The
# upstream archive is tried first; when its bytes no longer match, our own copy,
# the grace-commons release tlapm-bf665f4 (the same two archives and the upstream
# BSD-2-Clause licence beside them), is tried; if neither matches, the script stops.
# It unpacks outside the repo: $TLAPM_HOME, default ~/.local/share/tlapm/1.6.0-pre-bf665f4.
TLAPM_HOME="${TLAPM_HOME:-$HOME/.local/share/tlapm/1.6.0-pre-bf665f4}"
TLAPM_UPSTREAM=https://github.com/tlaplus/tlapm/releases/download/1.6.0-pre
TLAPM_OURS=https://github.com/scottromack/grace-commons/releases/download/tlapm-bf665f4
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)   TLAPM_ASSET=tlapm-1.6.0-pre-arm64-darwin.tar.gz
                  TLAPM_SHA256=05945a4e2c72d96a60b180fdb89403b36f9ef7a16d2f247c49667cafffb20318 ;;
  Linux-x86_64)   TLAPM_ASSET=tlapm-1.6.0-pre-x86_64-linux-gnu.tar.gz
                  TLAPM_SHA256=1fcb037a300929d4bed8539511f65073fc19762abd9cea5260fe91d0f2d617df ;;
  *)              TLAPM_ASSET= ;;
esac
TLAPM_BIN="$TLAPM_HOME/tlapm/bin/tlapm"
if [ -z "$TLAPM_ASSET" ]; then
  echo "TLAPS        : no pinned build for $(uname -s)-$(uname -m); the audit proves nothing until one is installed (TLAPM=<path> overrides)"
elif [ -x "$TLAPM_BIN" ]; then
  echo "TLAPS        : $("$TLAPM_BIN" --version) already in $TLAPM_HOME"
else
  mkdir -p "$TLAPM_HOME"
  TLAPM_TGZ="$TLAPM_HOME/$TLAPM_ASSET"
  TLAPM_OK=
  for TLAPM_BASE in "$TLAPM_UPSTREAM" "$TLAPM_OURS"; do
    if curl -fsSL -o "$TLAPM_TGZ" "$TLAPM_BASE/$TLAPM_ASSET" \
       && [ "$(shasum -a 256 "$TLAPM_TGZ" | cut -d' ' -f1)" = "$TLAPM_SHA256" ]; then
      TLAPM_OK=1; break
    fi
    echo "TLAPS        : $TLAPM_BASE/$TLAPM_ASSET did not give the pinned bytes (sha256 $TLAPM_SHA256)" >&2
    rm -f "$TLAPM_TGZ"
  done
  if [ -z "$TLAPM_OK" ]; then
    echo "TLAPS        : no source gave the pinned bytes for $TLAPM_ASSET; not installed" >&2
    exit 1
  fi
  tar -xzf "$TLAPM_TGZ" -C "$TLAPM_HOME"
  rm -f "$TLAPM_TGZ"
  echo "TLAPS        : $("$TLAPM_BIN" --version) installed in $TLAPM_HOME"
fi
# The arm64 archive ships an x86_64 z3, which needs Rosetta (sudo to install). Without
# Rosetta, put Homebrew's native z3 in its place (brew install z3); the original stays as z3.x86_64.
TLAPM_Z3="$TLAPM_HOME/tlapm/lib/tlapm/backends/bin/z3"
if [ -x "$TLAPM_BIN" ] && [ "$(uname -s)-$(uname -m)" = Darwin-arm64 ] && ! "$TLAPM_Z3" --version >/dev/null 2>&1; then
  BREW_Z3="$(brew --prefix z3 2>/dev/null || true)/bin/z3"
  if [ -x "$BREW_Z3" ]; then
    mv "$TLAPM_Z3" "$TLAPM_Z3.x86_64"
    ln -s "$BREW_Z3" "$TLAPM_Z3"
    echo "TLAPS z3     : the archive's x86_64 z3 needs Rosetta; linked Homebrew's $("$BREW_Z3" --version)"
  else
    echo "TLAPS z3     : the archive's x86_64 z3 needs Rosetta and no native z3 was found — run: brew install z3, then bootstrap.sh again"
  fi
fi

echo
echo "Ready. Examples:"
echo "  node check.mjs ../../grants/tla-poc/MultiPartyApproval.tla"
echo "  node check.mjs ../../grants/tla-poc/MultiPartyApprovalBuggy.tla --buggy"
echo "  node check.mjs ../../compositions/models/session-gated-authorization.als"
echo "  node audit.mjs        # run every existing model"
