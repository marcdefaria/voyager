FROM node:20-slim

WORKDIR /app

COPY server/package*.json ./
RUN npm ci --only=production

COPY server/ .
COPY voyager_system_prompt.md ./

EXPOSE 3000

CMD ["node", "index.js"]
