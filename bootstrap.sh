#!/bin/bash
# ==========================================
# Script Semilla (Bootstrap) para Servidor Nuevo
# ==========================================

echo "🚀 Iniciando el Bootstrap del Servidor..."

# 1. Seguridad: Comprobar que somos root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Debes ejecutar este comando como root (su -)"
  exit 1
fi

# 2. Instalar dependencias vitales de forma silenciosa (-yqq)
echo "📦 Instalando Git y Sudo..."
apt-get update -yqq
apt-get install -yqq git sudo curl wget

# 3. Descargar el código fuente
REPO_DIR="/home/gsx/scripting_gsx"

echo "📥 Descargando la infraestructura desde GitHub..."
# Borramos la carpeta si ya existía para hacer una instalación limpia
rm -rf "$REPO_DIR"
git clone https://github.com/pauplanasc/scripting_gsx.git "$REPO_DIR"

# 4. Ajustar permisos
echo "🔑 Ajustando permisos del proyecto..."
chown -R gsx:gsx "$REPO_DIR"
chmod -R +x "$REPO_DIR"

# 5. Prevenir el bug de Sudoers (Dar corona a gsx)
echo "👑 Otorgando poderes de administrador a gsx..."
usermod -aG sudo gsx

# 6. Lanzar la Semana 1
echo "⚙️ Ejecutando el orquestador de la Semana 1..."
cd "$REPO_DIR/week_1"
bash deploy.sh

echo "=========================================="
echo "✅ ¡INFRAESTRUCTURA BASE COMPLETADA!"
echo "🔌 Escribe 'exit' para salir de root, o reinicia la sesión para que apliquen los cambios."
echo "=========================================="