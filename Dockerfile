# ─── Stage 1: Build Flutter Web ─────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.22.0 AS builder

WORKDIR /app
COPY . .

# Download Arabic fonts
RUN mkdir -p assets/fonts && \
    apt-get update && apt-get install -y wget unzip && \
    wget -q "https://github.com/aliftype/amiri/releases/download/1.000/Amiri-1.000.zip" -O amiri.zip && \
    unzip -j amiri.zip "*.ttf" -d assets/fonts/ && \
    rm amiri.zip

RUN flutter pub get
RUN flutter pub run build_runner build --delete-conflicting-outputs
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --web-renderer canvaskit

# ─── Stage 2: Serve with nginx ───────────────────────────────────────────────
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html

# nginx config for SPA routing
RUN cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # SPA fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
}
EOF

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
