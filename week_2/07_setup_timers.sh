#!/bin/bash
# 07_setup_timers.sh
# Propósito: Crear servicio y timer en systemd para el backup automatizado.

set -euo pipefail

BACKUP_SCRIPT="/opt/admin/scripts/04_backup.sh"
SYSTEMD_DIR="/etc/systemd/system"

echo ">>> Configurando automatización de backups con systemd timers..."

# Verificar que el script de backup existe
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "ADVERTENCIA: $BACKUP_SCRIPT no existe en la ruta destino."
    echo "Asegúrate de copiar los scripts a /opt/admin/scripts antes de que el timer se dispare."
fi

# 1. Crear el archivo .service (El "Qué" hacer)
cat <<EOF > "$SYSTEMD_DIR/admin-backup.service"
[Unit]
Description=Ejecucion del script de backup del sistema
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash $BACKUP_SCRIPT
User=root
Group=sysadmins
EOF

# 2. Crear el archivo .timer (El "Cuándo" hacerlo)
cat <<EOF > "$SYSTEMD_DIR/admin-backup.timer"
[Unit]
Description=Timer para ejecutar admin-backup.service diariamente

[Timer]
# Ejecutar todos los días a las 02:00 AM
OnCalendar=*-*-* 02:00:00
# Si el servidor estaba apagado, ejecutar inmediatamente al encender:
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 3. Activar el Timer
systemctl daemon-reload
systemctl enable --now admin-backup.timer

echo ">>> Timer activado. Comprueba su estado con: systemctl list-timers admin-backup.timer"