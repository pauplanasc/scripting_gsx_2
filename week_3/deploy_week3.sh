#!/bin/bash
# deploy_week3.sh
# Propósito: Desplegar la Week 3 (Gestión de Procesos), corregir nombres y verificar límites.

set -euo pipefail

# --- Configuración Base ---
LOG_FILE="/var/log/setup_week3.log"
LOCK_FILE="/tmp/setup_week3.lock"
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"

# --- Funciones ---
log() {
    local type="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$type] $message" | tee -a "$LOG_FILE"
}

cleanup() {
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        log "INFO" "Bloqueo liberado."
    fi
}

error_handler() {
    log "CRITICAL" "Error en línea $1. Revisa el log."
    exit 1
}

# --- Validaciones ---
if [[ $EUID -ne 0 ]]; then
   echo "Error: Debes ser root (sudo)."
   exit 1
fi

touch "$LOCK_FILE"
trap 'cleanup' EXIT
trap 'error_handler ${LINENO}' ERR

log "INFO" ">>> Iniciando despliegue de Week 3 (Process Management)..."

# ==============================================================================
# FASE 1: CORRECCIONES Y PREPARACIÓN (Housekeeping)
# ==============================================================================
log "INFO" "Preparando scripts y herramientas..."

# 1. Corregir el nombre del script 13 (de .service a .sh)
WRONG_FILE="$SCRIPTS_DIR/13_signal_demo.service"
RIGHT_FILE="$SCRIPTS_DIR/13_signal_demo.sh"

if [ -f "$WRONG_FILE" ]; then
    log "WARNING" "Detectado archivo mal nombrado (13_signal_demo.service). Corrigiendo..."
    mv "$WRONG_FILE" "$RIGHT_FILE"
    log "SUCCESS" "Renombrado a 13_signal_demo.sh"
fi

# 2. Dar permisos de ejecución a TODAS las herramientas de la carpeta
# (No las ejecutamos aún, solo las preparamos para que tú las uses)
chmod +x "$SCRIPTS_DIR"/*.sh
log "SUCCESS" "Permisos de ejecución (+x) aplicados a todos los scripts."


# ==============================================================================
# FASE 2: DESPLIEGUE DE INFRAESTRUCTURA (Lo que debe correr en background)
# ==============================================================================
log "INFO" "Desplegando servicios persistentes..."

SERVICE_SCRIPT="15_limited_workload_service.sh"
FULL_PATH="$SCRIPTS_DIR/$SERVICE_SCRIPT"

if [ -f "$FULL_PATH" ]; then
    log "INFO" "Ejecutando instalación del servicio limitado ($SERVICE_SCRIPT)..."
    # Ejecutamos el script 15 porque este SÍ instala cosas en el sistema
    "$FULL_PATH"
    log "SUCCESS" "Servicio 'limited-workload' instalado y arrancado."
else
    log "ERROR" "No se encuentra $SERVICE_SCRIPT. ¿Falta el archivo?"
    exit 1
fi


# ==============================================================================
# FASE 3: VERIFICACIÓN (Health Check)
# ==============================================================================
log "INFO" "Verificando límites de cgroups (Quality Assurance)..."

VERIFY_SCRIPT="16_verify_cgroup_limits.sh"
VERIFY_PATH="$SCRIPTS_DIR/$VERIFY_SCRIPT"

if [ -f "$VERIFY_PATH" ]; then
    echo "---------------------------------------------------"
    # Ejecutamos la verificación y mostramos salida en pantalla
    "$VERIFY_PATH"
    echo "---------------------------------------------------"
    log "SUCCESS" "Verificación completada."
else
    log "WARNING" "Script de verificación ($VERIFY_SCRIPT) no encontrado."
fi


# ==============================================================================
# RESUMEN FINAL PARA EL ADMIN
# ==============================================================================
log "INFO" ">>> Despliegue finalizado exitosamente."
echo ""
echo "=================================================================="
echo "   WEEK 3 LISTA: MANUAL DE USO RÁPIDO"
echo "=================================================================="
echo "1. Para ver quién consume más CPU ahora mismo:"
echo "   $SCRIPTS_DIR/09_top_consumers.sh"
echo ""
echo "2. Para ver el árbol de procesos:"
echo "   $SCRIPTS_DIR/10_tree_relationships.sh"
echo ""
echo "3. Para inspeccionar un proceso específico (ej. nginx):"
echo "   $SCRIPTS_DIR/11_process_metrics.sh nginx"
echo ""
echo "4. Para probar señales (Graceful Shutdown) en una terminal aparte:"
echo "   $SCRIPTS_DIR/12_workload_generator.sh 2"
echo ""
echo "El servicio limitado ya está corriendo en background."
echo "=================================================================="