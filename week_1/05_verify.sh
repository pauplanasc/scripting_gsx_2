#!/bin/bash
# 05_verify.sh
# Propósito: Auditar que el estado del sistema cumple los requisitos de la Week 1.

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

check_item() {
    if eval "$1"; then
        echo -e "[ ${GREEN}OK${NC} ] $2"
    else
        echo -e "[ ${RED}FAIL${NC} ] $2"
        EXIT_CODE=1
    fi
}

echo ">>> Iniciando auditoría del sistema..."
EXIT_CODE=0

# 1. Verificación de Paquetes
check_item "dpkg -l | grep -q fail2ban" "Paquete fail2ban instalado"
check_item "dpkg -l | grep -q git" "Paquete git instalado"
check_item "dpkg -l | grep -q ufw" "Paquete ufw instalado"

# 2. Verificación de Usuarios y Grupos
ADMIN_USER="admin_sys" 
ADMIN_GROUP="sysadmins"

check_item "getent group $ADMIN_GROUP > /dev/null" "Grupo $ADMIN_GROUP existe"
check_item "id $ADMIN_USER &>/dev/null" "Usuario $ADMIN_USER existe"
check_item "id -nG $ADMIN_USER | grep -qw sudo" "Usuario $ADMIN_USER tiene sudo"

# 3. Verificación de Directorio y Permisos SGID
DIR="/opt/admin"
check_item "[ -d $DIR ]" "Directorio $DIR existe"

# Verificar bit SGID (2000) en permisos
PERM=$(stat -c "%a" $DIR)
if [[ "$PERM" == *"2"* ]] || [[ "$PERM" == *"s"* ]]; then
     echo -e "[ ${GREEN}OK${NC} ] Permisos SGID configurados en $DIR ($PERM)"
else
     echo -e "[ ${RED}FAIL${NC} ] Permisos SGID incorrectos en $DIR: $PERM"
     EXIT_CODE=1
fi

# 4. Verificación SSH (Solo config, no conexión)
check_item "grep -q '^PermitRootLogin no' /etc/ssh/sshd_config" "SSH: Root login deshabilitado"

echo ">>> Auditoría finalizada."
exit $EXIT_CODE