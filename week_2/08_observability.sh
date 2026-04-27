#!/bin/bash
# 08_observability.sh
# Propósito: Limitar tamaño de logs (journald) y crear script de auditoría rápida.

set -euo pipefail

echo ">>> Configurando Journald y herramientas de observabilidad..."

JOURNAL_CONF="/etc/systemd/journald.conf"

# 1. Limitar el tamaño de los logs a 200MB para evitar discos llenos
if grep -q "^#SystemMaxUse=" "$JOURNAL_CONF" || ! grep -q "^SystemMaxUse=" "$JOURNAL_CONF"; then
    sed -i 's/.*SystemMaxUse=.*/SystemMaxUse=200M/' "$JOURNAL_CONF" || echo "SystemMaxUse=200M" >> "$JOURNAL_CONF"
fi

systemctl restart systemd-journald

# 2. Crear un comando de atajo para los administradores
CAT_SCRIPT="/usr/local/bin/check-services"
cat << 'EOF' > "$CAT_SCRIPT"
#!/bin/bash
echo -e "\n=== ESTADO DE NGINX ==="
systemctl status nginx --no-pager | grep -E "Active:|Restart="

echo -e "\n=== ÚLTIMOS ERRORES DEL SISTEMA (Journalctl) ==="
journalctl -p 3 -xb -n 5 --no-pager

echo -e "\n=== ESTADO DE BACKUPS ==="
systemctl list-timers admin-backup.timer --no-pager
EOF

chmod +x "$CAT_SCRIPT"

echo ">>> Observabilidad configurada. Escribe 'check-services' en la terminal para un reporte rápido."