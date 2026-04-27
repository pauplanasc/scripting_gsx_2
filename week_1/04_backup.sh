#!/bin/bash
# 04_backup.sh
# Propósito: Script automatizado de copias de seguridad.

set -euo pipefail

ORIGEN="/etc"
DESTINO="/opt/admin/backups"
FECHA=$(date +%Y-%m-%d_%H-%M)
NOMBRE_ARCHIVO="backup_etc_${FECHA}.tar.gz"

echo "Iniciando backup de $ORIGEN..."
mkdir -p "$DESTINO"
tar -czf "$DESTINO/$NOMBRE_ARCHIVO" "$ORIGEN" 2>/dev/null

echo "Backup completado exitosamente: $DESTINO/$NOMBRE_ARCHIVO"