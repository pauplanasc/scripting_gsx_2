#!/bin/bash
# 20_env_config.sh
# Propósito: Personalizar el shell de los usuarios automáticamente.

set -euo pipefail

PROFILE_SCRIPT="/etc/profile.d/greendevcorp_env.sh"
BIN_DIR="/home/greendevcorp/bin"

echo ">>> Configurando entorno compartido..."

cat <<EOF > "$PROFILE_SCRIPT"
# Configuración específica para el equipo GreenDevCorp
# Se carga automáticamente al iniciar sesión.

# 1. Añadir scripts compartidos al PATH
if [ -d "$BIN_DIR" ]; then
    export PATH="\$PATH:$BIN_DIR"
fi

# 2. Alias útiles para el equipo
alias ll='ls -la'
alias work='cd /home/greendevcorp/shared'
alias mytasks='cat /home/greendevcorp/done.log'

# 3. Bienvenida personalizada
echo "Bienvenido al servidor de desarrollo GreenDevCorp."
echo "Recuerda: El directorio compartido es /home/greendevcorp/shared"
EOF

# Dar permisos de lectura
chmod 644 "$PROFILE_SCRIPT"

echo "Script de entorno creado en $PROFILE_SCRIPT"