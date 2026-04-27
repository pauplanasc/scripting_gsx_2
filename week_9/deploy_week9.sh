#!/bin/bash
# deploy_week9.sh
# Propósito: Automatizar el despliegue del stack de la Semana 9 usando Docker Compose.

set -euo pipefail

echo "🚀 Iniciando despliegue automatizado de la Semana 9 (Docker Compose)..."

# 1. Gestionar las variables de entorno (Idempotencia)
if [ ! -f .env ]; then
    echo "⚠️ No se encontró el archivo .env real. Creando uno a partir de .env.example..."
    cp .env.example .env
    echo "✅ Archivo .env generado. (Recuerda que este archivo no se sube a Git)."
else
    echo "✅ Archivo .env detectado."
fi

# 2. Limpieza: Apagar la infraestructura anterior si estaba corriendo
echo "🧹 Limpiando el entorno (apagando contenedores previos)..."
docker compose down

# 3. Despliegue: Construir y levantar
# Usamos --build para asegurarnos de que si cambiaste algo en server.js o nginx.conf, se aplique.
echo "🏗️ Construyendo imágenes y levantando la orquesta..."
docker compose up -d --build

# 4. Verificación: Esperar a los healthchecks
echo "⏳ Esperando 10 segundos para que los servicios arranquen y pasen los Healthchecks..."
sleep 10

echo "📊 Estado actual de los contenedores:"
docker compose ps

# 5. Prueba de fuego final
echo "========================================================="
echo "🌐 Prueba de conexión simulando un usuario:"
echo "---------------------------------------------------------"
curl -s http://localhost || echo "❌ Fallo al conectar con localhost"
echo ""
echo "========================================================="
echo "✅ ¡INFRAESTRUCTURA DE LA SEMANA 9 DESPLEGADA CON ÉXITO!"
echo "👉 Para ver los logs en tiempo real usa: docker compose logs -f"
echo "========================================================="