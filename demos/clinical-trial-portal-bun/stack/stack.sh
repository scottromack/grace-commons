#!/usr/bin/env bash
# The stack Beacon is rendered on, pinned: Bun 1.3.2 (npm's `bun` package, so
# an arm64 machine with no Rosetta runs it), Hono 4.13.19, postgres 4.1.1, and
# XTDB 2.2.0 on Temurin 21 over its Postgres wire port.
#
#   bash stack/stack.sh install   fetch the JDK and the XTDB jar into .stack/ (checked against their sha256)
#   bash stack/stack.sh start     start XTDB in memory on 127.0.0.1:5432 (health on 8080)
#   bash stack/stack.sh stop
#   bash stack/stack.sh restart   stop and start: XTDB runs in memory, so this is a fresh store (the tests start from one)
#
# XTDB 2 is published as a container image only; its jar is the one layer that
# holds /usr/local/lib/xtdb/xtdb.jar, fetched here by digest from ghcr.io, so no
# container runtime is needed. macOS arm64 only for now.
set -euo pipefail
cd "$(dirname "$0")/.."
S=.stack
JDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.13%2B9/OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.13_9.tar.gz"
JDK_SHA=bf036b35b071bfb2f54f2c0af8ee8d88afa95ee6eb3dce02c0f94cfc2524d04a
XT_LAYER=sha256:7a7f6d3207e555a67ad5803f8ad4f0852370dc17ed1266c022a04a862907fe00   # ghcr.io/xtdb/xtdb:2.2.0, linux/arm64, the layer holding xtdb.jar
XT_SHA=${XT_LAYER#sha256:}
JAVA="$S/jdk/jdk-21.0.13+9/Contents/Home/bin/java"

check() { [ "$(shasum -a 256 "$1" | cut -d' ' -f1)" = "$2" ] || { echo "sha256 of $1 does not match the pin" >&2; exit 1; }; }

case "${1:-}" in
  install)
    mkdir -p "$S/jdk" "$S/xtdb"
    [ -x "$JAVA" ] || { curl -sL "$JDK_URL" -o "$S/jdk.tgz"; check "$S/jdk.tgz" "$JDK_SHA"; tar xzf "$S/jdk.tgz" -C "$S/jdk"; rm "$S/jdk.tgz"; }
    if [ ! -f "$S/xtdb/xtdb.jar" ]; then
      tok=$(curl -s 'https://ghcr.io/token?scope=repository:xtdb/xtdb:pull' | sed -E 's/.*"token":"([^"]+)".*/\1/')
      curl -sL -H "Authorization: Bearer $tok" "https://ghcr.io/v2/xtdb/xtdb/blobs/$XT_LAYER" -o "$S/xtdb.layer.tgz"
      check "$S/xtdb.layer.tgz" "$XT_SHA"
      tar xzf "$S/xtdb.layer.tgz" -C "$S/xtdb" --strip-components=4 usr/local/lib/xtdb/xtdb.jar
      rm "$S/xtdb.layer.tgz"
    fi
    echo "stack installed in $S"
    ;;
  start)
    [ -x "$JAVA" ] && [ -f "$S/xtdb/xtdb.jar" ] || { echo "run: bash stack/stack.sh install" >&2; exit 1; }
    printf 'server:\n  port: 5432\nhealthz:\n  port: 8080\n' > "$S/xtdb/config.yaml"
    "$JAVA" --add-opens=java.base/java.nio=ALL-UNNAMED --enable-native-access=ALL-UNNAMED \
      -Dio.netty.tryReflectionSetAccessible=true -Dio.netty.noUnsafe=false \
      -cp "$S/xtdb/xtdb.jar" clojure.main -m xtdb.main -f "$S/xtdb/config.yaml" > "$S/xtdb/out.log" 2>&1 &
    echo $! > "$S/xtdb/pid"
    for _ in $(seq 1 60); do curl -sf http://127.0.0.1:8080/healthz/alive >/dev/null && { echo "xtdb up"; exit 0; }; sleep 1; done
    echo "xtdb did not start; see $S/xtdb/out.log" >&2; exit 1
    ;;
  stop)
    [ -f "$S/xtdb/pid" ] && kill "$(cat "$S/xtdb/pid")" 2>/dev/null || true
    rm -f "$S/xtdb/pid"
    # a store left running by an earlier start keeps the port: stop whatever still listens on it, then wait for the port to free
    for p in $(lsof -ti tcp:5432 -sTCP:LISTEN 2>/dev/null); do kill "$p" 2>/dev/null || true; done
    for _ in $(seq 1 20); do lsof -ti tcp:5432 -sTCP:LISTEN >/dev/null 2>&1 || break; sleep 0.5; done
    ;;
  restart)
    bash "$0" stop; sleep 1; bash "$0" start
    ;;
  *) echo "usage: stack.sh install|start|stop|restart" >&2; exit 2 ;;
esac
