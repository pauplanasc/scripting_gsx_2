FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
COPY . .

FROM node:20-alpine
WORKDIR /app
# Añadimos curl para poder hacer el Healthcheck (Nivel Intermedio)
RUN apk --no-cache add curl
USER node
COPY --from=builder --chown=node:node /app ./
EXPOSE 3000
CMD ["npm", "start"]