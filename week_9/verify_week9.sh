#!/bin/bash
# verify_week9.sh
# Propósito: Verificar la orquesta, healthchecks y persistencia de la Semana 9.

echo "🔍 Iniciando verificación de la Semana 9 (Docker Compose)..."
echo "----------------------------------------"

# 1. Verificar el estado global de Compose
COMPOSE_STATUS=$(docker compose ps)

# Comprobar Healthchecks
if [[ "$COMPOSE_STATUS" == *"(healthy)"* ]]; then
    echo "✅ Docker Compose: Los contenedores están arriba y pasando los Healthchecks."
else
    echo "❌ ERROR: Hay contenedores caídos o los Healthchecks están fallando."
fi

# 2. Verificar conexión y base de datos Redis
echo "----------------------------------------"
echo "🌐 Simulando peticiones web para probar Redis..."

# Hacer la primera petición
RESP_1=$(curl -s http://localhost || echo "Fallo")
# Extraer solo el número de la respuesta (magia de bash)
VISIT_1=$(echo "$RESP_1" | grep -oP 'numero: \K\d+')

if [[ -n "$VISIT_1" ]]; then
    echo "✅ Petición 1 exitosa. Visitante número: $VISIT_1"
else
    echo "❌ ERROR: Nginx o Node.js no están respondiendo."
    exit 1
fi

# Hacer una segunda petición para comprobar que el contador suma
RESP_2=$(curl -s http://localhost)
VISIT_2=$(echo "$RESP_2" | grep -oP 'numero: \K\d+')

if [ "$VISIT_2" -gt "$VISIT_1" ]; then
    echo "✅ Petición 2 exitosa. Visitante número: $VISIT_2"
    echo "✅ REDIS FUNCIONA: El contador se está incrementando correctamente."
else
    echo "❌ ERROR: El contador no sube. Redis podría estar fallando."
fi

echo "----------------------------------------"
echo "🏁 Verificación de la Semana 9 completada."