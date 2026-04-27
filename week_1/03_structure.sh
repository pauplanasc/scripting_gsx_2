#!/bin/bash
# 03_structure.sh
# Propósito: Crear estructura de admin y configurar Git

set -euo pipefail

BASE_DIR="/opt/admin"
ADMIN_GROUP="sysadmins"

echo ">>> Configurando entorno de administración..."

# 1. Crear directorios
mkdir -p "$BASE_DIR"/{scripts,config,logs,backups}

# 2. Permisos colaborativos (SGID)
# root es dueño, grupo sysadmins es el grupo dueño
chown -R root:"$ADMIN_GROUP" "$BASE_DIR"
# 2770: 2=SGID, 7=User RWX, 7=Group RWX, 0=Others None
chmod -R 2775 "$BASE_DIR"

echo "Permisos establecidos en $BASE_DIR (SGID activado)."

# 3. Inicializar Git si no existe
if [ ! -d "$BASE_DIR/.git" ]; then
    echo "Inicializando repositorio Git..."
    cd "$BASE_DIR"
    git init
    
    # Crear .gitignore básico
    cat <<EOF > .gitignore
logs/
backups/
*.log
.env
keys/
EOF
    echo ".gitignore creado."
else
    echo "Git ya estaba inicializado."
fi

echo ">>> Estructura completada."
