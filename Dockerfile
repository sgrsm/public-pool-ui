############################
# Docker build environment #
############################

FROM node:lts-bookworm-slim AS build

# Install build dependencies in a single layer and clean up afterwards
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        python3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /build

COPY . .

# Build Public Pool UI using NPM
RUN npm ci && npm run build

############################
# Docker final environment #
############################

FROM caddy:alpine AS final

LABEL org.opencontainers.image.title="public-pool-ui" \
      org.opencontainers.image.description="Web UI for Public Pool" \
      org.opencontainers.image.source="https://github.com/benjamin-wilson/public-pool-ui"

EXPOSE 80
WORKDIR /var/www/html

COPY --from=build /build/dist/public-pool-ui .
COPY docker/Caddyfile.tpl /etc/Caddyfile.tpl
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["wget","-q","-O","-","http://127.0.0.1:80"]

CMD ["/bin/sh", "/entrypoint.sh"]
