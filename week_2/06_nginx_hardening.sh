#!/bin/bash
# 06_nginx_hardening.sh
# Propósito: Instalar Nginx y configurar systemd para auto-recuperación (Restart=always).

set -euo pipefail

echo ">>> Configurando Nginx para alta disponibilidad..."

# 1. Instalar Nginx si no existe
if ! dpkg -l | grep -q nginx; then
    apt-get update && apt-get install nginx -y
fi

# 2. Crear un directorio de override (drop-in) para systemd
# NUNCA editamos el archivo original de /lib/systemd/
OVERRIDE_DIR="/etc/systemd/system/nginx.service.d"
mkdir -p "$OVERRIDE_DIR"

# 3. Inyectar la configuración de auto-recuperación
cat <<EOF > "$OVERRIDE_DIR/override.conf"
[Service]
# Reiniciar siempre, sin importar el código de error
Restart=always
# Esperar 5 segundos antes de reiniciar para evitar bucles de CPU
RestartSec=5
EOF

# 4. Aplicar cambios
systemctl daemon-reload
systemctl enable nginx
systemctl restart nginx

echo ">>> Nginx configurado y protegido contra caídas."