# =============================================================
# CloudShirt Hugo – Multi-stage Dockerfile
# Stage 1 : Build  (Go + Hugo extended voor Blowfish v2 theme)
# Stage 2 : Runtime (Nginx Alpine – klein en veilig)
# =============================================================

# ── Build stage ───────────────────────────────────────────────
FROM golang:1.24-alpine AS build

# Hugo extended vereist CGO (voor SCSS/SASS in Blowfish theme)
RUN apk add --no-cache git gcc musl-dev

# Hugo extended binary bouwen (v0.159.2)
ARG HUGO_VERSION=0.159.2
RUN go install github.com/gohugoio/hugo@v${HUGO_VERSION} \
    && hugo version

WORKDIR /site

# Go module cache eerst (layer-cache optimalisatie)
COPY go.mod go.sum ./
RUN go mod download

# Volledige broncode kopiëren (inclusief content/, config/, static/)
COPY . .

# Site bouwen: minified output, garbage collect unused resources
RUN hugo --minify --gc

# ── Runtime stage ─────────────────────────────────────────────
FROM nginx:alpine AS runtime

# Nginx configuratie voor Hugo (schone URLs, caching, security headers)
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Gegeneerde statische bestanden kopiëren uit build stage
COPY --from=build /site/public /usr/share/nginx/html

# Nginx luistert op poort 80
EXPOSE 80

# Health-check gebruikt door Docker Swarm en ALB target group
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
  CMD wget -qO- http://localhost/ || exit 1
