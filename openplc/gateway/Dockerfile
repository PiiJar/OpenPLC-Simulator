FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --production

COPY index.js modbus_map.js db.js event_consumer.js file_routes.js legacy_stubs.js production_dispatcher.js ./

EXPOSE 3001

CMD ["node", "index.js"]
