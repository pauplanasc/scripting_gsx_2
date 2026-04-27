#!/bin/bash
# 21_verify_week4.sh
# Propósito: Verificar permisos, acceso y límites.

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo ">>> Iniciando Auditoría de Seguridad Week 4..."

# 1. Verificar Permisos de Directorios
echo -e "\n[TEST 1] Verificando permisos especiales..."
PERM_SHARED=$(stat -c "%a" /home/greendevcorp/shared)
# Buscamos 3770 (1=sticky, 2=sgid, 770=rwx) -> stat a veces devuelve 3770 o 2770+t
if [[ "$PERM_SHARED" == "3770" ]]; then
    echo -e "${GREEN}[OK]${NC} /shared tiene Sticky Bit y SGID correctos ($PERM_SHARED)."
else
    echo -e "${RED}[FAIL]${NC} /shared tiene permisos incorrectos: $PERM_SHARED (Esperado: 3770)"
fi

# 2. Verificar Log (Solo dev1 puede escribir)
echo -e "\n[TEST 2] Verificando acceso a done.log..."
# Prueba de escritura como dev2 (Debería fallar)
if sudo -u dev2 bash -c "echo 'Intento hack' >> /home/greendevcorp/done.log" 2>/dev/null; then
    echo -e "${RED}[FAIL]${NC} dev2 pudo escribir en done.log (ERROR DE SEGURIDAD)."
else
    echo -e "${GREEN}[OK]${NC} dev2 NO pudo escribir en done.log (Correcto)."
fi

# Prueba de escritura como dev1 (Debería funcionar)
if sudo -u dev1 bash -c "echo 'Tarea completada por dev1' >> /home/greendevcorp/done.log" 2>/dev/null; then
    echo -e "${GREEN}[OK]${NC} dev1 pudo escribir en done.log."
else
    echo -e "${RED}[FAIL]${NC} dev1 NO pudo escribir en done.log."
fi

# 3. Verificar Variables de Entorno
echo -e "\n[TEST 3] Verificando entorno..."
if sudo -u dev1 bash -c 'echo $PATH' | grep -q "/home/greendevcorp/bin"; then
    echo -e "${GREEN}[OK]${NC} El PATH incluye el directorio bin compartido."
else
    echo -e "${RED}[FAIL]${NC} El PATH no se actualizó correctamente."
fi

echo -e "\n>>> Auditoría finalizada."