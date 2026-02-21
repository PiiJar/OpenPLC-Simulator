# PLC Simulator backend (sim-core) container
FROM node:18-alpine

WORKDIR /app

# Install only production dependencies for lean image
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy server code and data assets
COPY sim-core ./sim-core
COPY visualization ./visualization

EXPOSE 3001

ENV PORT=3001
CMD ["node", "sim-core/server.js"]
