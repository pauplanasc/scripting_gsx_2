#!/bin/bash
set -eo pipefail

# Validación de argumento
PROCESS_NAME="${1:?Error: Debes proporcionar el nombre de un proceso (ej. nginx)}"

echo "Extrayendo métricas para: $PROCESS_NAME"
echo "----------------------------------------------------------------"

# Capturamos la salida en una variable para validar existencia
# El '|| true' evita que pipefail mate el script si grep no encuentra nada
DATA=$(ps aux | grep "[${PROCESS_NAME:0:1}]${PROCESS_NAME:1}" | awk '{print $1, $2, $3, $4, $11}' || true)

if [ -z "$DATA" ]; then
    echo "Aviso: No se encontraron procesos activos con el nombre '$PROCESS_NAME'."
    exit 0 # Idempotencia: terminar con éxito aunque no haya datos
fi

echo -e "USER PID %CPU %MEM COMMAND\n$DATA" | column -t