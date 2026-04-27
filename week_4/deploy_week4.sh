#!/bin/bash
# deploy_week4.sh
# Orquestador para la configuración de Team Collaboration

set -euo pipefail

# Asegurarse de ser root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root."
   exit 1
fi

chmod +x *.sh

echo "=== INICIANDO DESPLIEGUE WEEK 4 ==="
./17_create_users.sh
./18_setup_permissions.sh
./19_setup_limits.sh
./20_env_config.sh

echo -e "\n=== EJECUTANDO VERIFICACIÓN ==="
./21_verify_week4.sh

echo -e "\n=== DESPLIEGUE COMPLETADO ==="