# Build stage
FROM node:22-alpine AS builder

# Pass API URL at build time so Vite bakes it into the bundle (e.g. --build-arg VITE_API_URL=http://backend.fullstack-app.local:30814)
ARG VITE_API_URL=http://backend.fullstack-app.local:30814

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
# Remove .env so it doesn't override VITE_API_URL (e.g. local dev .env with localhost:4000)
RUN rm -f .env .env.local .env.*.local
# Set env in same RUN as build so Vite bakes this into the bundle (not overridable at runtime)
RUN export VITE_API_URL="${VITE_API_URL}" && \
    echo "Building with VITE_API_URL=${VITE_API_URL}" && \
    npm run build

# Production stage: install serve so we don't run npx at runtime (saves memory and startup time in k8s)
FROM node:22-alpine

WORKDIR /app
COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["npx", "--yes", "serve", "-s", "dist", "-l", "3000"]
