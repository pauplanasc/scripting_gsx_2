#!/bin/bash
# 23_advanced_backup.sh
# Propósito: Realizar backups incrementales usando rsync para ahorrar espacio.

set -euo pipefail

SOURCE_DIR="/home/greendevcorp/shared" # Lo que queremos respaldar
BACKUP_ROOT="/mnt/data_vault/backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
LATEST_LINK="$BACKUP_ROOT/latest"
CURRENT_BACKUP="$BACKUP_ROOT/backup_$DATE"

echo ">>> Iniciando backup incremental de $SOURCE_DIR..."

mkdir -p "$BACKUP_ROOT"

# Usamos rsync con --link-dest. Esto compara con el último backup. 
# Si un archivo no ha cambiado, crea un "Hard Link" (acceso directo que ocupa 0 bytes)
# en lugar de copiar el archivo entero otra vez.
if [ -d "$LATEST_LINK" ]; then
    rsync -a --delete --link-dest="$LATEST_LINK" "$SOURCE_DIR/" "$CURRENT_BACKUP/"
else
    # Primer backup (Full)
    rsync -a "$SOURCE_DIR/" "$CURRENT_BACKUP/"
fi

# Actualizar el enlace al "último backup"
rm -f "$LATEST_LINK"
ln -s "$CURRENT_BACKUP" "$LATEST_LINK"

echo ">>> Backup exitoso: $CURRENT_BACKUP"