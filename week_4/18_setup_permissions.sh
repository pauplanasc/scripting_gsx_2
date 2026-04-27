#!/bin/bash
# 18_setup_permissions.sh
# Propósito: Configurar directorios compartidos, SGID y Sticky Bits.

set -euo pipefail

BASE_DIR="/home/greendevcorp"
BIN_DIR="$BASE_DIR/bin"
SHARED_DIR="$BASE_DIR/shared"
LOG_FILE="$BASE_DIR/done.log"
GROUP_NAME="greendevcorp"
ADMIN_USER="dev1"

echo ">>> Configurando permisos y directorios..."

# Crear directorio base si no existe
if [ ! -d "$BASE_DIR" ]; then
    mkdir -p "$BASE_DIR"
fi

# 1. Directorio /bin (Scripts compartidos)
# Requisito: Ejecutable por miembros del equipo solamente.
mkdir -p "$BIN_DIR"
chown root:"$GROUP_NAME" "$BIN_DIR"
# 750: Root(RWX), Grupo(R-X), Otros(---) -> Nadie fuera del grupo puede entrar
chmod 750 "$BIN_DIR"
echo "Configurado $BIN_DIR (750 root:$GROUP_NAME)"

# 2. Directorio /shared (Trabajo colaborativo)
# Requisito: SetGID (herencia de grupo) y Sticky Bit (protección de borrado).
mkdir -p "$SHARED_DIR"
chown root:"$GROUP_NAME" "$SHARED_DIR"
# 2770: 2(SGID) + 7(User RWX) + 7(Group RWX) + 0(Others None)
# +t (Sticky Bit): Solo el dueño de un archivo puede borrarlo, aunque el grupo tenga W.
chmod 2770 "$SHARED_DIR"
chmod +t "$SHARED_DIR"
echo "Configurado $SHARED_DIR (SGID + Sticky Bit + 2770)"

# 3. Archivo done.log (Log de tareas)
# Requisito: Legible por todos, escribible SOLO por dev1.
touch "$LOG_FILE"
chown "$ADMIN_USER":"$GROUP_NAME" "$LOG_FILE"
# 640: Dueño(RW), Grupo(R), Otros(---) -> Least Privilege (Otros no necesitan leer esto)
chmod 640 "$LOG_FILE"
echo "Configurado $LOG_FILE (Owner: $ADMIN_USER, Perms: 640)"

echo ">>> Estructura de permisos aplicada."