#!/bin/bash
# 02_users_ssh.sh
# Propósito: Crear usuarios, asignar sudo y asegurar SSH.

set -euo pipefail

# VARIABLES 
ADMIN_USER="admin_sys"
ADMIN_GROUP="sysadmins"

echo ">>> Configurando usuarios y acceso..."

# 1. Crear grupo de administración si no existe
if ! getent group "$ADMIN_GROUP" > /dev/null; then
    groupadd "$ADMIN_GROUP"
    echo "Grupo $ADMIN_GROUP creado."
fi

# 2. Crear usuario si no existe
if ! id "$ADMIN_USER" &>/dev/null; then
    # -m crea home, -s define shell, -G añade a grupos secundarios
    useradd -m -s /bin/bash -G sudo,"$ADMIN_GROUP" "$ADMIN_USER"
    echo "Usuario $ADMIN_USER creado. ¡IMPORTANTE! Asigna una contraseña manualmente con: passwd $ADMIN_USER"
else
    echo "El usuario $ADMIN_USER ya existe. Verificando grupos..."
    usermod -aG sudo,"$ADMIN_GROUP" "$ADMIN_USER"
fi

# 3. Habilitar sudo sin contraseña 
SUDO_FILE="/etc/sudoers.d/$ADMIN_USER"
if [ ! -f "$SUDO_FILE" ]; then
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > "$SUDO_FILE"
    chmod 0440 "$SUDO_FILE"
    echo "Sudo sin contraseña configurado para $ADMIN_USER."
fi

# 4. Hardening de SSH (Edición segura de sshd_config)
SSHD_CONFIG="/etc/ssh/sshd_config"
echo "Asegurando SSH..."

# Función auxiliar para asegurar configuración
configure_ssh_param() {
    local param=$1
    local value=$2
    if grep -q "^$param" "$SSHD_CONFIG"; then
        sed -i "s/^$param.*/$param $value/" "$SSHD_CONFIG"
    else
        echo "$param $value" >> "$SSHD_CONFIG"
    fi
}

# Realizar copias de seguridad antes de tocar nada
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak"

configure_ssh_param "PermitRootLogin" "no"          # Prohibir root directo
configure_ssh_param "PasswordAuthentication" "yes"  # CAMBIAR A 'no' DESPUÉS DE COPIAR KEYS
configure_ssh_param "PubkeyAuthentication" "yes"

# Reiniciar SSH para aplicar cambios
systemctl restart sshd

echo ">>> Usuarios y SSH configurados."
