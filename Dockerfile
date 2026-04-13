# ─── Stage 1: Build Flutter Web ─────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY . .

# ⚠️  API_BASE_URL DOIT être passé en build argument dans Coolify
#    (Settings > Build Variables > API_BASE_URL = https://<votre-backend>)
#    Le fallback localhost ne fonctionne qu'en développement local.
ARG API_BASE_URL=http://localhost:8000

RUN flutter pub get
RUN dart run build_runner build --delete-conflicting-outputs
RUN flutter build web --release --no-tree-shake-icons --no-wasm-dry-run \
    --dart-define=API_BASE_URL=${API_BASE_URL}

# ── Generate version.json ────────────────────────────────────────────────────
# Written to build/web/ so nginx serves it at /version.json.
# The app fetches this on startup and every 5 min; a changed value triggers
# the in-app "Nouvelle version disponible" banner → window.location.reload().
# Uses git short hash if available, falls back to a UTC timestamp.
RUN VERSION=$(git rev-parse --short HEAD 2>/dev/null || date -u +%Y%m%d%H%M%S) && \
    echo "{\"version\":\"$VERSION\"}" > build/web/version.json

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

    # version.json must NEVER be cached — it's the update detection sentinel
    location = /version.json {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        expires 0;
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
