#!/bin/bash
# deploy_week8.sh
# Propósito: Automatizar el despliegue de los contenedores en el servidor de Producción.

set -euo pipefail

# Variable con tu usuario de Docker Hub
DOCKER_USER="pauplanasc"

echo "🚀 Iniciando despliegue automatizado de la Semana 8 (Contenedores)..."

# 1. Asegurar que Docker está instalado (Llama al script anterior si hace falta)
if ! command -v docker &> /dev/null; then
    echo "⚠️ Docker no está instalado. Instalándolo primero..."
    # Asume que install_docker.sh está en el directorio padre o en el repo
    sudo curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    sudo systemctl enable --now docker
    echo "✅ Docker instalado. Continuando..."
fi

# 2. Apagar el Nginx antiguo (monolítico) para liberar el puerto 80
if systemctl is-active --quiet nginx; then
    echo "🛑 Deteniendo Nginx nativo de la Semana 2 para evitar conflictos de puerto..."
    sudo systemctl stop nginx
    # Opcional: sudo systemctl disable nginx para que no vuelva a arrancar al reiniciar
fi

# 3. Limpiar contenedores previos si existen (Idempotencia)
# El '|| true' evita que el script falle si los contenedores no existen
echo "🧹 Limpiando contenedores antiguos..."
docker rm -f prod_nginx 2>/dev/null || true
docker rm -f prod_simple_app 2>/dev/null || true

# 4. Desplegar aplicación Simple (Node.js)
echo "📦 Descargando y levantando Simple App (Node.js)..."
# Usamos --restart unless-stopped para que si el servidor se reinicia, el contenedor arranque solo
docker run -d -p 3000:3000 --name prod_simple_app --restart unless-stopped "$DOCKER_USER/simple-app-gsx:v1"

# 5. Desplegar Nginx
echo "🌐 Descargando y levantando Nginx Container..."
docker run -d -p 80:8080 --name prod_nginx --restart unless-stopped "$DOCKER_USER/nginx-gsx:v1"

echo "========================================================="
echo "✅ ¡INFRAESTRUCTURA DE LA SEMANA 8 DESPLEGADA CON ÉXITO!"
echo "👉 Prueba la web Nginx: curl http://localhost"
echo "👉 Prueba la Node App:  curl http://localhost:3000"
echo "========================================================="