FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --production

COPY index.js modbus_map.js ./

EXPOSE 3001

CMD ["node", "index.js"]
