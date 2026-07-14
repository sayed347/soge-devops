# --- Build stage ---
# Debian-based, not Alpine — musl libc crashes under QEMU arm64 emulation
# with Node's JIT (illegal instruction), glibc doesn't.
FROM node:20-bookworm-slim AS build
WORKDIR /build
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# --- Run stage ---
# Non-root variant of the official nginx image (runs as uid 101, listens on
# unprivileged ports) so the container never needs root.
FROM nginxinc/nginx-unprivileged:alpine
COPY --from=build /build/dist /usr/share/nginx/html
COPY nginx/templates /etc/nginx/templates

EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -q --spider http://localhost:8080/ || exit 1
