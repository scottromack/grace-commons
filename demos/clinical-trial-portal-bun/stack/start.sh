#!/usr/bin/env bash
# The container's one command (SPEC.md, Running it): XTDB in memory on 127.0.0.1:5432, then Beacon once the store's health answers.
# If either process ends the other is stopped and the container ends with it, so the platform restarts both together.
set -euo pipefail
cd "$(dirname "$0")/.."
X=${XTDB_DIR:-/opt/xtdb}
JAVA=${JAVA:-java}
printf 'server:\n  port: 5432\nhealthz:\n  port: 8080\n' > "${XTDB_CONFIG:-/tmp/xtdb.yaml}"
"$JAVA" ${JAVA_OPTS:--Xmx512m} --add-opens=java.base/java.nio=ALL-UNNAMED --enable-native-access=ALL-UNNAMED \
  -Dio.netty.tryReflectionSetAccessible=true -Dio.netty.noUnsafe=false \
  -cp "$X/xtdb.jar" clojure.main -m xtdb.main -f "${XTDB_CONFIG:-/tmp/xtdb.yaml}" &
store=$!
for _ in $(seq 1 90); do curl -sf http://127.0.0.1:8080/healthz/alive >/dev/null && break; kill -0 "$store" 2>/dev/null || { echo "xtdb ended before it was up" >&2; exit 1; }; sleep 1; done
curl -sf http://127.0.0.1:8080/healthz/alive >/dev/null || { echo "xtdb did not come up in 90 seconds" >&2; kill "$store"; exit 1; }
${BUN:-bun} src/main.ts &
app=$!
trap 'kill "$store" "$app" 2>/dev/null || true' TERM INT
while kill -0 "$store" 2>/dev/null && kill -0 "$app" 2>/dev/null; do sleep 1; done
kill "$store" "$app" 2>/dev/null || true
exit 1
