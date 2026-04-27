#!/bin/bash
# deploy.sh
# Propósito: Orquestar la ejecución segura de todos los scripts de configuración.

# 1. Configuración de seguridad estricta
set -euo pipefail

# 2. Variables Globales
LOG_FILE="/var/log/setup_deploy.log"
LOCK_FILE="/tmp/setup_deploy.lock"
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"

# 3. Funciones Auxiliares
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

# 4. Validaciones Iniciales
if [[ $EUID -ne 0 ]]; then
   echo "Error: Este script debe ejecutarse como root (o con sudo)."
   exit 1
fi

if [ -f "$LOCK_FILE" ]; then
    echo "CRÍTICO: El archivo de bloqueo $LOCK_FILE existe. Hay otro despliegue en curso."
    exit 1
fi

touch "$LOCK_FILE"
trap 'cleanup' EXIT
trap 'error_handler ${LINENO}' ERR

# 5. Ejecución Secuencial (Scripts 01 al 04)
log "INFO" "Iniciando despliegue maestro..."
log "INFO" "Directorio de scripts: $SCRIPTS_DIR"

DECLARE_SCRIPTS=(
    "01_setup_base.sh"
    "02_users_ssh.sh"
    "03_structure.sh"
    "04_backup.sh"
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
        log "WARNING" "El script $script no se encontró. Saltando..."
    fi
done

log "INFO" ">>> Despliegue de infraestructura completado."

# 6. Post-Deployment Health Check (Auditoría automática)
log "INFO" "Iniciando auditoría automática (05_verify.sh)..."

VERIFY_SCRIPT="$SCRIPTS_DIR/05_verify.sh"
if [ -f "$VERIFY_SCRIPT" ]; then
    chmod +x "$VERIFY_SCRIPT"
    
    # Ejecutamos la verificación. Al estar dentro de un 'if', evitamos que 
    # el 'set -e' aborte el deploy entero bruscamente si la auditoría falla.
    if "$VERIFY_SCRIPT"; then
        echo ""
        log "SUCCESS" "¡Auditoría superada! El sistema cumple todos los requisitos."
    else
        echo ""
        log "WARNING" "El despliegue terminó, pero la auditoría reportó fallos en rojo. Revisa la salida superior."
    fi
else
    log "WARNING" "No se encontró el script de verificación ($VERIFY_SCRIPT)."
fi

log "INFO" ">>> Proceso total finalizado. Puedes revisar el historial en: $LOG_FILE"