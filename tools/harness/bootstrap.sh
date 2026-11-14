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
# bytes, and a checksum that no longer matches stops this script rather than
# installing them. Pinned: tlaplus/tlapm tag 1.6.0-pre at commit
# ff40755301b84455d368f9f8b13fe9fdb0bc9407 (`tlapm --version` prints ff40755).
# It unpacks outside the repo: $TLAPM_HOME, default ~/.local/share/tlapm/1.6.0-pre.
TLAPM_HOME="${TLAPM_HOME:-$HOME/.local/share/tlapm/1.6.0-pre}"
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)   TLAPM_ASSET=tlapm-1.6.0-pre-arm64-darwin.tar.gz
                  TLAPM_SHA256=76c2b7871fce30f26543e432d0e2cff506450fc90f70d18f7a032cf05a614a16 ;;
  Linux-x86_64)   TLAPM_ASSET=tlapm-1.6.0-pre-x86_64-linux-gnu.tar.gz
                  TLAPM_SHA256=99db29f119cb6f43ffed653b212ba2d005e5bf8e242c53468876cb0d08da6bcc ;;
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
  curl -fsSL -o "$TLAPM_TGZ" "https://github.com/tlaplus/tlapm/releases/download/1.6.0-pre/$TLAPM_ASSET"
  TLAPM_GOT="$(shasum -a 256 "$TLAPM_TGZ" | cut -d' ' -f1)"
  if [ "$TLAPM_GOT" != "$TLAPM_SHA256" ]; then
    echo "TLAPS        : checksum mismatch for $TLAPM_ASSET (got $TLAPM_GOT, pinned $TLAPM_SHA256): the rolling release moved; not installed" >&2
    rm -f "$TLAPM_TGZ"
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
