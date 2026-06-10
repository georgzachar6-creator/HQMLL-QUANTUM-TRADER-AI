# HQMLL Quantum Trader AI — Multi-stage Dockerfile
# Stage 1: Build React Enterprise Web
FROM node:18-alpine AS web-build
WORKDIR /app
COPY web/frontend/package*.json ./
RUN npm ci --silent
COPY web/frontend/ ./
RUN npm run build

# Stage 2: Serve with nginx
FROM nginx:stable-alpine AS web-server
COPY --from=web-build /app/dist /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
