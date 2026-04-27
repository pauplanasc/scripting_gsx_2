# ==========================================
# Etapa 1: Build (Instalación de dependencias)
# ==========================================
FROM node:20-alpine AS builder
WORKDIR /app
# Copiamos solo el package.json primero (Optimización de capas/Caché)
COPY package*.json ./
RUN npm install --only=production
# Copiamos el resto del código
COPY . .

# ==========================================
# Etapa 2: Runtime (Imagen final ligera y segura)
# ==========================================
FROM node:20-alpine
WORKDIR /app

# Nivel Intermedio: Seguridad (No correr como Root)
# La imagen de node incluye un usuario llamado 'node' por defecto
USER node

# Copiamos solo lo necesario desde la Etapa 1 con los permisos correctos
COPY --from=builder --chown=node:node /app ./

EXPOSE 3000
CMD ["npm", "start"]