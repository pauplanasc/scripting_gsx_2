#!/bin/bash
# verify_week8.sh
# Propósito: Preparar el entorno automáticamente y verificar la Semana 8.

set -euo pipefail

echo "⚙️  Fase 1: PREPARANDO EL ENTORNO PARA LA SEMANA 8..."
echo "----------------------------------------------------"

# 1. Apagar la Semana 9 si está encendida (para liberar puertos)
if [ -d "../week_9" ]; then
    echo "🛑 Apagando contenedores de la Semana 9 (Docker Compose)..."
    cd ../week_9
    docker compose down 2>/dev/null || true
    cd ../week_8
fi

# 2. Desplegar la Semana 8
echo "🏗️  Levantando infraestructura de la Semana 8..."
./deploy_week8.sh > /dev/null 2>&1
echo "✅ Entorno preparado."
echo ""

echo "🔍 Fase 2: INICIANDO VERIFICACIÓN..."
echo "----------------------------------------------------"

# 1. Verificar si los contenedores están corriendo
if docker ps | grep -q "prod_simple_app"; then
    echo "✅ Contenedor Node.js (prod_simple_app) está EN EJECUCIÓN."
else
    echo "❌ ERROR: El contenedor Node.js no está corriendo."
fi

if docker ps | grep -q "prod_nginx"; then
    echo "✅ Contenedor Nginx (prod_nginx) está EN EJECUCIÓN."
else
    echo "❌ ERROR: El contenedor Nginx no está corriendo."
fi

# 2. Verificar las respuestas de red (cURL)
echo "----------------------------------------------------"
echo "🌐 Verificando puertos y respuestas web..."

# Probar Node.js (Puerto 3000)
NODE_RESPONSE=$(curl -s http://localhost:3000 || echo "Fallo")
if [[ "$NODE_RESPONSE" == *"Hello from container"* ]]; then
    echo "✅ Puerto 3000: La aplicación Node.js responde correctamente."
else
    echo "❌ ERROR en Puerto 3000: Respuesta incorrecta o sin conexión."
fi

# Probar Nginx (Puerto 80)
NGINX_RESPONSE=$(curl -s http://localhost || echo "Fallo")
if [[ "$NGINX_RESPONSE" == *"GreenDevCorp"* ]]; then
    echo "✅ Puerto 80: El servidor Nginx responde correctamente."
else
    echo "❌ ERROR en Puerto 80: Respuesta incorrecta o sin conexión."
fi

echo "----------------------------------------------------"
echo "🏁 Verificación de la Semana 8 completada con éxito."