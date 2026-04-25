FROM caddy:2-alpine

# Godot 4 web exports require SharedArrayBuffer, which the browser only enables
# when the page is served with strict cross-origin isolation headers. Caddyfile
# sets COOP/COEP for every response so the WASM bootstrap succeeds.
COPY Caddyfile /etc/caddy/Caddyfile
COPY web_build/ /srv/

EXPOSE 8080
