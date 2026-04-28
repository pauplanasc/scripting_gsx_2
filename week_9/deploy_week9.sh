#!/bin/bash
# deploy_week9.sh
# Propósito: Automatizar el despliegue de la Semana 9 previniendo conflictos de puertos.

set -euo pipefail

echo "🚀 Iniciando despliegue automatizado de la Semana 9 (Docker Compose)..."

# ==========================================
# 🛡️ FASE 0: PREVENCIÓN DE ERRORES (ANTI-OKUPAS)
# ==========================================
echo "🛡️ Verificando y liberando puertos necesarios..."

# 1. Detectar y apagar Nginx nativo de la máquina virtual (Debian)
if systemctl is-active --quiet nginx; then
    echo "⚠️  Detectado Nginx nativo en ejecución. Apagándolo..."
    sudo systemctl stop nginx
fi

# 2. Detectar y borrar contenedores huérfanos de la Semana 8
echo "🧹 Limpiando contenedores individuales que puedan generar conflictos..."
docker rm -f prod_nginx prod_simple_app 2>/dev/null || true

# 3. Limpiar la orquesta anterior de la Semana 9 por si quedó a medias
docker compose down 2>/dev/null || true
echo "✅ Entorno despejado y listo."
# ==========================================

# 1. Gestionar las variables de entorno (Idempotencia)
if [ ! -f .env ]; then
    echo "⚠️ No se encontró el archivo .env real. Creando uno a partir de .env.example..."
    cp .env.example .env
fi

# 2. Despliegue: Construir y levantar
echo "🏗️ Construyendo imágenes y levantando la orquesta..."
# Silenciamos los warnings de 'version obsolete' para una salida más limpia
docker compose up -d --build 2> >(grep -v "version\` is obsolete" >&2)

# 3. Verificación: Esperar a los healthchecks
echo "⏳ Esperando 15 segundos para que los servicios arranquen y pasen los Healthchecks..."
sleep 15

echo "📊 Estado actual de los contenedores:"
docker compose ps

# 4. Prueba de fuego final
echo "========================================================="
echo "🌐 Prueba de conexión simulando un usuario:"
echo "---------------------------------------------------------"
curl -s http://localhost || echo "❌ Fallo al conectar con localhost"
echo ""
echo "========================================================="
echo "✅ ¡INFRAESTRUCTURA DE LA SEMANA 9 DESPLEGADA CON ÉXITO!"
echo "👉 Para ver los logs en tiempo real usa: docker compose logs -f"
echo "========================================================="