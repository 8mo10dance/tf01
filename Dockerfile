FROM node:20.8.0 AS client-builder

ARG BUILD_ENV=production

WORKDIR /app/client

COPY client/package.json client/package-lock.json ./
RUN npm ci

COPY client/ ./
RUN npm run build:${BUILD_ENV}

FROM nginx:1.31.3-alpine

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=client-builder /app/client/public/ /usr/share/nginx/html/

EXPOSE 80
