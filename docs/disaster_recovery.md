# 🚑 Disaster Recovery & Verified Backup (DRP)

Este documento detalla el procedimiento de recuperación de datos para el servidor de GreenDevCorp, así como la evidencia de las pruebas de restauración.

## 📊 Tiempos Objetivo de Recuperación
* **RPO (Recovery Point Objective):** 24 horas. Los backups automatizados vía systemd timers se ejecutan cada madrugada a las 02:00 AM. En el peor escenario de pérdida total del disco principal, la pérdida máxima de datos es de un día de trabajo.
* **RTO (Recovery Time Objective):** < 5 minutos. Al utilizar `rsync` con copias exactas y hard links en un disco virtual secundario (`/mnt/data_vault`), la recuperación no requiere descompresión de archivos pesados. Es una copia directa bloque a bloque.

---

## 🛠️ Procedimiento de Recuperación Completo (Full Recovery)

En caso de pérdida de datos en el entorno de desarrollo compartido (`/home/greendevcorp/shared`), sigue estos pasos:

### 1. Identificar el último backup válido
Los backups se almacenan en el disco secundario `/dev/sdb`, montado en `/mnt/data_vault`.
\`\`\`bash
# Listar las copias disponibles ordenadas por fecha
sudo ls -l /mnt/data_vault/backups/
\`\`\`
*(Nota: Siempre existirá una carpeta llamada `latest` que apunta mediante un enlace simbólico al backup más reciente).*

### 2. Detener servicios que escriban en disco (Opcional pero recomendado)
Para evitar que los usuarios modifiquen archivos mientras se restaura:
\`\`\`bash
sudo systemctl stop nginx
sudo killall -u dev1 dev2 dev3 dev4 2>/dev/null
\`\`\`

### 3. Ejecutar la Restauración
Se utiliza `rsync` para volcar los datos desde la bóveda de seguridad al directorio de producción. El flag `--delete` asegura que los archivos corruptos actuales se borren y queden exactamente como en el backup.
\`\`\`bash
sudo rsync -av --delete /mnt/data_vault/backups/latest/ /home/greendevcorp/shared/
\`\`\`

### 4. Restaurar Permisos de Seguridad (SGID)
Las restauraciones pueden alterar los permisos especiales. Es crítico volver a forzar la política de la empresa:
\`\`\`bash
sudo chown -R root:greendevcorp /home/greendevcorp/shared
sudo chmod -R 2770 /home/greendevcorp/shared
sudo chmod +t /home/greendevcorp/shared
\`\`\`

---

## ✅ Evidencia de Recuperación (Testing)

La recuperación ha sido verificada en un entorno de pruebas simulando un borrado accidental ("Fat-finger error").

**Escenario de Prueba:**
1. Se generó el archivo crítico `proyecto_final.sh` en `/home/greendevcorp/shared/`.
2. Se forzó la ejecución del timer: `sudo systemctl start admin-backup.service`.
3. Se comprobó la creación exitosa en: `/mnt/data_vault/backups/latest/proyecto_final.sh`.
4. El usuario simuló un borrado accidental: `rm -rf /home/greendevcorp/shared/*`.
5. Se ejecutó el comando de restauración del procedimiento superior.
6. **Resultado:** El archivo `proyecto_final.sh` fue restaurado con su contenido intacto y los permisos `greendevcorp` correctos en 1.2 segundos.