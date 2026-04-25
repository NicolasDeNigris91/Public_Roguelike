# Multi-stage build: Godot exports the Web target in stage 1, Caddy serves
# the resulting static bundle in stage 2. web_build/ is no longer committed.

# ---- Stage 1: build the HTML5 bundle ----
FROM debian:bookworm-slim AS builder

ENV GODOT_VERSION=4.6.2-stable \
    GODOT_TEMPLATE_DIR=4.6.2.stable \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        wget ca-certificates unzip \
    && rm -rf /var/lib/apt/lists/*

# Godot Linux binary, pinned to the version the rest of the project targets.
RUN wget -qO /tmp/godot.zip \
        "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
    && unzip -q /tmp/godot.zip -d /tmp \
    && mv "/tmp/Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm /tmp/godot.zip

# Export templates for the Web target, placed where Godot expects them.
RUN wget -qO /tmp/templates.tpz \
        "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz" \
    && mkdir -p "/root/.local/share/godot/export_templates/${GODOT_TEMPLATE_DIR}" \
    && unzip -q /tmp/templates.tpz -d /tmp/tpl \
    && mv /tmp/tpl/templates/* "/root/.local/share/godot/export_templates/${GODOT_TEMPLATE_DIR}/" \
    && rm -rf /tmp/templates.tpz /tmp/tpl

WORKDIR /project
COPY . .

# --import primes the .godot cache so class_name / autoload lookups resolve.
# --quit-after 2 caps the editor session; a non-zero code here is usually
# a benign template warning, so don't fail the build on it.
RUN godot --headless --import --quit-after 2 || true
RUN mkdir -p web_build \
    && godot --headless --export-release "Web" web_build/index.html \
    && test -s web_build/index.wasm

# ---- Stage 2: serve via Caddy with COOP/COEP ----
FROM caddy:2-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=builder /project/web_build/ /srv/

EXPOSE 8080
