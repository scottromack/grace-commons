# Beacon on Fly: Bun 1.3.2 and Hono, XTDB 2.2.0 in memory beside it on Temurin 21 (STACK.md, SPEC.md Running it).
# XTDB's jar comes from its own image, pinned by the index digest of ghcr.io/xtdb/xtdb:2.2.0; Bun from its own image.
FROM ghcr.io/xtdb/xtdb@sha256:a6a426505b95a36e4e0e1d0de88efcf4220cb6bde8f1f5e594b0a1f92a948a77 AS xtdb
FROM oven/bun:1.3.2-debian AS bun

FROM eclipse-temurin:21.0.13_9-jre
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
COPY --from=xtdb /usr/local/lib/xtdb/xtdb.jar /opt/xtdb/xtdb.jar
WORKDIR /app
COPY package.json package-lock.json ./
RUN bun install --production
COPY src ./src
COPY stack/start.sh ./stack/start.sh
ENV PORT=8000 SECURE_COOKIE=1
EXPOSE 8000
CMD ["bash", "stack/start.sh"]
