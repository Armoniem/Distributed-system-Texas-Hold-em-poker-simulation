# ─── Stage 1: Build Flutter web ───────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Cache pubspec layer
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy all source
COPY . .

# Build for web – BACKEND_URL injected at build time via --dart-define
ARG BACKEND_URL=http://localhost:8080
RUN flutter build web \
    --release \
    --dart-define=BACKEND_URL=${BACKEND_URL} \
    --dart-define=ENV=production \
    --no-tree-shake-icons

# ─── Stage 2: Serve with Nginx ───────────────────────────────────────────────
FROM nginx:1.25-alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/pokereval.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
