#!/bin/bash
# 24_nfs_setup.sh
# Propósito: Configurar NFS para compartir almacenamiento por la red.

set -euo pipefail

SHARED_DIR="/mnt/data_vault/nfs_shared"
NETWORK="192.168.0.0/16" # Ajusta esto a la IP de tu red de VirtualBox si lo pruebas desde otra VM

echo ">>> Configurando Servidor NFS..."

# Instalar NFS
if ! dpkg -l | grep -q nfs-kernel-server; then
    apt-get update && apt-get install nfs-kernel-server -y
fi

# Configurar exportación
if ! grep -q "$SHARED_DIR" /etc/exports; then
    # rw: lectura/escritura, sync: escribe en disco inmediatamente, no_root_squash: permite a root de otra máquina escribir
    echo "$SHARED_DIR *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
fi

# Aplicar cambios
exportfs -arv
systemctl restart nfs-kernel-server

echo ">>> NFS configurado. Carpeta compartida: $SHARED_DIR"