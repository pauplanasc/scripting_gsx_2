#!/bin/bash
# 25_verify_week5.sh
# Propósito: Verificar que el disco, el backup y el NFS funcionan.

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo ">>> Iniciando Auditoría Week 5..."

# 1. Verificar Disco Montado
if mountpoint -q /mnt/data_vault; then
    echo -e "${GREEN}[OK]${NC} El disco nuevo está montado en /mnt/data_vault."
else
    echo -e "${RED}[FAIL]${NC} El disco no está montado."
fi

# 2. Verificar Backup
if [ -L "/mnt/data_vault/backups/latest" ]; then
    echo -e "${GREEN}[OK]${NC} Se detectó un sistema de backups incrementales activo."
else
    echo -e "${RED}[FAIL]${NC} No se encontró el enlace 'latest' del backup."
fi

# 3. Verificar NFS
if exportfs -v | grep -q "/mnt/data_vault/nfs_shared"; then
    echo -e "${GREEN}[OK]${NC} Servidor NFS exportando la carpeta compartida correctamente."
else
    echo -e "${RED}[FAIL]${NC} NFS no está exportando la carpeta."
fi