#!/bin/bash
# 17_create_users.sh
# Propósito: Crear estructura de usuarios y grupos para el equipo de desarrollo.

set -euo pipefail

GROUP_NAME="greendevcorp"
USERS=("dev1" "dev2" "dev3" "dev4")
DEFAULT_PASS="GreenDev2026!" # Contraseña por defecto para pruebas

echo ">>> Configurando usuarios y grupos..."

# 1. Crear el grupo del equipo
if ! getent group "$GROUP_NAME" > /dev/null; then
    groupadd "$GROUP_NAME"
    echo "Grupo '$GROUP_NAME' creado."
else
    echo "El grupo '$GROUP_NAME' ya existe."
fi

# 2. Crear usuarios y asignarlos al grupo
for user in "${USERS[@]}"; do
    if ! id "$user" &>/dev/null; then
        # -m: Crear home directory
        # -s: Shell por defecto bash
        # -G: Grupo secundario (el del equipo)
        useradd -m -s /bin/bash -G "$GROUP_NAME" "$user"
        
        # Asignar contraseña (necesario para login y pruebas PAM)
        echo "$user:$DEFAULT_PASS" | chpasswd
        
        # Forzar cambio de contraseña en primer login (buena práctica de seguridad)
        chage -d 0 "$user"
        
        echo "Usuario '$user' creado y añadido a '$GROUP_NAME'."
    else
        echo "El usuario '$user' ya existe. Asegurando membresía de grupo..."
        usermod -aG "$GROUP_NAME" "$user"
    fi
done

echo ">>> Gestión de usuarios completada."