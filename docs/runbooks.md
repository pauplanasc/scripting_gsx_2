# 📘 Manual de Operaciones (Runbook) - GreenDevCorp

Este documento es la guía de referencia rápida para los ingenieros de operaciones de GreenDevCorp. Contiene los procedimientos estandarizados para las tareas del día a día, resolución de problemas comunes (Troubleshooting) y vías de escalado.

---

## 🔄 1. Tareas Comunes (How do I...?)

### ¿Cómo añado a un nuevo desarrollador al equipo?
Los desarrolladores deben pertenecer al grupo `greendevcorp` para heredar los permisos del directorio compartido y los límites de recursos (PAM). Para añadir un nuevo usuario (ej. `dev5`):

\`\`\`bash
# 1. Crear el usuario y añadirlo al grupo principal
sudo useradd -m -g greendevcorp -s /bin/bash dev5

# 2. Asignar una contraseña temporal (se le pedirá cambiarla al entrar)
sudo passwd dev5
sudo chage -d 0 dev5
\`\`\`

### ¿Cómo gestiono la salida de un miembro del equipo?
Si un desarrollador abandona la empresa, **no debemos borrar su usuario inmediatamente** (`userdel`), ya que podríamos crear archivos huérfanos. Debemos bloquear su acceso:

\`\`\`bash
# 1. Bloquear la contraseña de la cuenta
sudo usermod -L dev1

# 2. Expirar la cuenta inmediatamente para cerrar sesiones activas
sudo chage -E 0 dev1
\`\`\`
*(Nota: Gracias al SGID implementado en `/home/greendevcorp/shared`, el resto del equipo podrá seguir editando los archivos que creó este usuario).*

### ¿Cómo compruebo si los servicios funcionan correctamente?
Nuestra infraestructura se basa en `systemd`. Para auditar la salud del servidor:

* **Servidor Web (Nginx):** `sudo systemctl status nginx`
* **Sistema de Backups (Timers):** `sudo systemctl list-timers | grep backup`
* **Ver logs en tiempo real:** `sudo journalctl -u nginx -f`
* **Auditoría rápida (Script propio):** `check-services` (Comando global instalado en la Semana 2).

### ¿Cómo diagnostico un sistema lento?
No confíes solo en `top` o `htop`. Utiliza las herramientas de diagnóstico personalizadas que implementamos en la **Semana 3**:

1. **Identificar quién consume más recursos:** \`\`\`bash
   /opt/admin/week_3/09_top_consumers.sh
   \`\`\`
2. **Revisar si los límites de Cgroups están actuando:** \`\`\`bash
   systemd-cgtop
   \`\`\`
3. **Ver la jerarquía de procesos (¿Hay procesos zombie?):**
   \`\`\`bash
   /opt/admin/week_3/10_tree_relationships.sh
   \`\`\`

### ¿Cómo restauro desde un backup?
Tenemos un RTO (Recovery Time Objective) de minutos. Para restaurar el directorio compartido a su estado de la noche anterior:

\`\`\`bash
sudo rsync -av --delete /mnt/data_vault/backups/latest/ /home/greendevcorp/shared/
\`\`\`
*(Para el procedimiento completo de desastres y restauración de bases de datos, consulta el [Plan de Disaster Recovery](disaster_recovery.md)).*

---

## 🚨 2. Guía de Troubleshooting (Resolución de Problemas)

| Síntoma / Error | Causa Probable | Solución Inmediata |
| :--- | :--- | :--- |
| **"Permission denied" al editar un archivo en `/shared`** | El archivo fue copiado o creado sin heredar el grupo correcto. | Ejecutar `sudo chown -R root:greendevcorp /home/greendevcorp/shared` y asegurar que la carpeta tiene SGID (`chmod 2770`). |
| **Nginx aparece como "Failed" o reiniciándose en bucle** | Error de sintaxis en la configuración o el puerto 80 está ocupado. | Ejecutar `sudo nginx -t` para ver en qué línea está el error tipográfico. Corregir y hacer `sudo systemctl restart nginx`. |
| **"No space left on device" en `/mnt/data_vault`** | El disco virtual secundario de backups (5GB) se ha llenado. | Limpiar copias manuales antiguas o ajustar la política de retención del script de *rsync* en la Semana 5. |
| **Usuario administrador no puede ejecutar `sudo`** | La sesión no se ha refrescado o el usuario perdió el grupo. | Entrar como root puro (`su -`) y ejecutar `usermod -aG sudo <usuario>`. Salir y volver a iniciar sesión. |

---

## 📞 3. Procedimientos de Escalado (Escalation)

Si un problema crítico ocurre en producción y no puede resolverse en **30 minutos** usando este Runbook, sigue este orden estricto de escalado:

1. **Nivel 1 (Operaciones Básicas):** Reiniciar el servicio afectado (`systemctl restart <servicio>`) y verificar espacio en disco (`df -h`).
2. **Nivel 2 (Diagnóstico Avanzado):** Buscar errores críticos a nivel de kernel (`dmesg -T | tail -n 20`) y revisar los logs generales del sistema (`journalctl -xe`).
3. **Nivel 3 (Escalado Crítico):** Si el servidor está inaccesible por SSH, Nginx no levanta, o hay pérdida de datos confirmada:
   * **Contactar inmediatamente** a los Administradores de Sistemas Senior (Pau Planas / [Nombre Compañero]).
   * Abrir un ticket de *Incidencia Crítica (P1)* en el repositorio de GitHub detallando los últimos comandos ejecutados.