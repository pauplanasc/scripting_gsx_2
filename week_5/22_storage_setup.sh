#!/bin/bash
# 22_storage_setup.sh
# Propósito: Particionar, formatear y montar un nuevo disco duro de forma persistente.

set -euo pipefail

DISK="/dev/sdb"
MOUNT_POINT="/mnt/data_vault"

echo ">>> Iniciando configuración de almacenamiento..."

# 1. Verificar si el disco existe
if [ ! -b "$DISK" ]; then
    echo "ERROR: El disco $DISK no existe. ¿Añadiste el disco en VirtualBox?"
    exit 1
fi

# 2. Particionar y formatear (Solo si no está formateado ya)
if ! blkid "$DISK" | grep -q "ext4"; then
    echo "Formateando $DISK a ext4..."
    # parted en modo silencioso crea una partición GPT que ocupa todo el disco
    parted -s "$DISK" mklabel gpt mkpart primary ext4 0% 100%
    mkfs.ext4 "${DISK}1"
else
    echo "El disco $DISK ya tiene formato ext4. Saltando formateo."
fi

# 3. Crear punto de montaje y montar
mkdir -p "$MOUNT_POINT"
mount "${DISK}1" "$MOUNT_POINT" || true # Evita error si ya estaba montado

# 4. Hacerlo persistente en /etc/fstab
UUID=$(blkid -s UUID -o value "${DISK}1")
if ! grep -q "$UUID" /etc/fstab; then
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab
    echo "Disco añadido a /etc/fstab exitosamente."
fi

# 5. Crear estructura interna para copias y equipo
mkdir -p "$MOUNT_POINT/backups"
mkdir -p "$MOUNT_POINT/nfs_shared"
chown -R root:sysadmins "$MOUNT_POINT"
chmod -R 2775 "$MOUNT_POINT"

echo ">>> Almacenamiento configurado en $MOUNT_POINT"