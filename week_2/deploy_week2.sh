#!/bin/bash
# deploy_week2.sh
# Propósito: Orquestar el despliegue de los servicios, timers y observabilidad (Week 2).

set -euo pipefail

# Variables Globales
LOG_FILE="/var/log/setup_week2.log"
LOCK_FILE="/tmp/setup_week2.lock"
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"

# Funciones Auxiliares
log() {
    local type="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$type] $message" | tee -a "$LOG_FILE"
}

cleanup() {
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        log "INFO" "Bloqueo liberado. Ejecución finalizada."
    fi
}

error_handler() {
    local line_no=$1
    log "CRITICAL" "Error fatal en la línea $line_no. Abortando instalación."
    exit 1
}

# Validaciones Iniciales
if [[ $EUID -ne 0 ]]; then
   echo "Error: Este script debe ejecutarse como root (usa: sudo ./deploy_week2.sh)."
   exit 1
fi

if [ -f "$LOCK_FILE" ]; then
    echo "CRÍTICO: El archivo de bloqueo $LOCK_FILE existe. Hay otro despliegue en curso."
    exit 1
fi

touch "$LOCK_FILE"
trap 'cleanup' EXIT
trap 'error_handler ${LINENO}' ERR

# Ejecución Secuencial
log "INFO" "Iniciando despliegue de la Week 2 (Servicios y Automatización)..."
log "INFO" "Directorio de scripts: $SCRIPTS_DIR"

DECLARE_SCRIPTS=(
    "06_nginx_hardening.sh"
    "07_setup_timers.sh"
    "08_observability.sh"
)

for script in "${DECLARE_SCRIPTS[@]}"; do
    full_path="$SCRIPTS_DIR/$script"
    
    if [ -f "$full_path" ]; then
        log "INFO" "Ejecutando: $script..."
        chmod +x "$full_path"
        
        if "$full_path"; then
            log "SUCCESS" "$script finalizado correctamente."
        else
            log "ERROR" "$script falló."
            exit 1
        fi
    else
        log "WARNING" "El script $script no se encontró. Asegúrate de que existe en $SCRIPTS_DIR."
        exit 1 # Aquí sí salimos porque son servicios críticos
    fi
done

log "INFO" ">>> Despliegue de servicios completado."

# Verificación automática final
log "INFO" "Ejecutando auditoría de servicios..."
echo "------------------------------------------------"
if command -v check-services &> /dev/null; then
    check-services
else
    log "WARNING" "No se encontró el comando check-services. ¿Falló el script 08?"
fi
echo "------------------------------------------------"

log "INFO" ">>> Proceso total finalizado. Puedes revisar el historial en: $LOG_FILE"