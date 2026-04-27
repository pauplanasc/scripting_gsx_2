#!/bin/bash
# 19_setup_limits.sh
# Propósito: Configurar límites de recursos (CPU, Memoria, Procesos) para evitar abusos.

set -euo pipefail

LIMITS_CONF="/etc/security/limits.d/greendevcorp.conf"
GROUP_NAME="greendevcorp"

echo ">>> Configurando límites de recursos (PAM)..."

# Creamos un archivo dedicado en limits.d en lugar de ensuciar limits.conf principal
cat <<EOF > "$LIMITS_CONF"
# Límites para el grupo @greendevcorp
# item: puede ser core, data, fsize, memlock, nofile, rss, stack, cpu, nproc...

# 1. Máximo número de procesos (Evitar Fork Bombs)
@$GROUP_NAME    hard    nproc           50

# 2. Máximo número de archivos abiertos
@$GROUP_NAME    hard    nofile          100

# 3. Límite de memoria (RSS - Resident Set Size) en KB (Ej. 500MB)
@$GROUP_NAME    hard    rss             500000

# 4. Prioridad de CPU (Evitar que acaparen la CPU, nice value)
@$GROUP_NAME    hard    priority        10
EOF

echo "Límites configurados en $LIMITS_CONF"
echo "NOTA: Estos límites se aplican al iniciar nueva sesión (login)."