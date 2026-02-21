# Backend + sim-core container
FROM node:18-alpine

WORKDIR /app

# Install dependencies first (cache-friendly)
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy backend core and visualization assets (JSON/CSV served by server.js)
COPY sim-core ./sim-core
COPY visualization ./visualization

# Expose API port
EXPOSE 3001

CMD ["node", "sim-core/server.js"]
