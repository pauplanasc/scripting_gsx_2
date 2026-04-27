#!/bin/bash
# deploy_week5.sh
set -euo pipefail

echo "Comprobando dependencias..."
if ! command -v rsync &> /dev/null; then
    echo "rsync no encontrado. Instalando..."
    apt-get update && apt-get install rsync -y
else
    echo "rsync ya está instalado."
fi

if [[ $EUID -ne 0 ]]; then echo "Ejecuta con sudo."; exit 1; fi

chmod +x *.sh

echo "=== DESPLIEGUE WEEK 5: ALMACENAMIENTO Y BACKUPS ==="
./22_storage_setup.sh
./23_advanced_backup.sh
./24_nfs_setup.sh

echo -e "\n=== VERIFICACIÓN ==="
./25_verify_week5.sh