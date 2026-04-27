#!/bin/bash
# install_docker.sh
# Propósito: Instalar Docker Engine oficial y configurar permisos.

set -euo pipefail

echo "🚀 Iniciando preparación del entorno Docker..."

# 1. Seguridad: Comprobar que somos root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Error: Este script debe ejecutarse con sudo (ej: sudo ./install_docker.sh)"
   exit 1
fi

# 2. Comprobar si Docker ya existe (Idempotencia)
if command -v docker &> /dev/null; then
    echo "✅ Docker ya está instalado en el sistema."
    docker --version
else
    echo "📥 Descargando e instalando Docker Engine oficial..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo "✅ Instalación completada."
fi

# 3. Configurar permisos para el usuario
# Si lo ejecutas con sudo, $SUDO_USER guarda tu usuario real (ej: gsx)
TARGET_USER="${SUDO_USER:-gsx}"

if id "$TARGET_USER" &>/dev/null; then
    echo "👑 Otorgando permisos de Docker al usuario '$TARGET_USER'..."
    usermod -aG docker "$TARGET_USER"
    echo "⚠️ IMPORTANTE: Si es tu primera vez instalando, '$TARGET_USER' debe salir (exit) y volver a entrar por SSH."
else
    echo "⚠️ Advertencia: No se encontró al usuario '$TARGET_USER'."
fi

# 4. Asegurar que el servicio arranca automáticamente con el sistema
systemctl enable --now docker
echo "✅ Servicio Docker habilitado y en ejecución."

echo "=========================================="
echo "🎉 ¡Entorno Docker listo para producción!"
echo "=========================================="