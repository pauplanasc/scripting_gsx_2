# 🏗️ Documentación de Arquitectura y Diseño

Este documento detalla las decisiones de diseño, trade-offs y la planificación futura para la infraestructura del servidor de GreenDevCorp.

## Decisiones de Diseño por Fases

### Week 1: Foundational Server Administration
Para la configuración base, se optó por un enfoque modular e idempotente.
* **Estructura de Directorios (FHS):** Se utilizó `/opt/admin/` para almacenar scripts de administración en lugar de los directorios `/home`. Esto cumple con el estándar de jerarquía (FHS) para software que afecta a todo el sistema.
* **Seguridad SSH:** Se desactiva el acceso root por defecto, obligando al uso de usuarios sin privilegios que deben escalar permisos mediante `sudo`, garantizando la trazabilidad en los logs.

### Week 2: Services, Observability & Automation
El objetivo es la alta disponibilidad y la prevención de fallos silenciosos.
* **Auto-recuperación (Drop-in):** Para hacer que Nginx sea resiliente, se creó un *drop-in* en `/etc/systemd/system/nginx.service.d/`. Se descartó modificar directamente `/lib/systemd/system/nginx.service` porque las actualizaciones de `apt` sobrescribirían nuestros cambios.
* **Systemd Timers vs Cron:** Se decidió abandonar `cron` a favor de `systemd timers`. La razón es la observabilidad: los timers se integran nativamente con `journald`, permitiendo registrar la salida estándar (stdout/stderr) directamente en los logs del sistema.

### Week 3: Process Management & Resource Control
La visibilidad en los procesos es fundamental para diagnosticar cuellos de botella.
* **Escalabilidad Segura (cgroups):** Para evitar que procesos desbocados monopolicen el sistema, empaquetamos las cargas de trabajo en servicios systemd aplicando `CPUQuota=20%` y `MemoryMax=50M`.
* **Graceful Shutdown:** Se diseñaron scripts que responden a señales POSIX (`SIGTERM`, `SIGINT`), permitiendo limpiar procesos hijos antes de salir, en lugar de usar `SIGKILL` (fuerza bruta).

### Week 4: Collaborative Environment & Access Control
El reto era permitir la colaboración sin comprometer la seguridad.
* **Trade-off: Standard Permissions vs ACLs:** Se decidió usar permisos estándar de Linux (SGID y Sticky Bits) en el directorio `/shared` en lugar de Listas de Control de Acceso (ACLs). Las ACLs son más granulares, pero los permisos estándar son más universales, fáciles de auditar y menos propensos a errores de configuración.
* **Protección de Datos:** El **Sticky Bit** (1770) garantiza que un desarrollador solo pueda borrar los archivos que él mismo ha creado, protegiendo el trabajo del resto del equipo.
* **Límites PAM:** Se implementaron límites en `/etc/security/limits.d/` para restringir el número máximo de procesos por usuario, previniendo bombas lógicas (fork bombs) accidentales.

### Week 5: Storage & Backup Strategy
* **Trade-off: Incrementales vs Completos:** Hemos abandonado los backups completos (`tar`) a favor de incrementales con Hard Links usando `rsync`. Esto ahorra muchísimo espacio en disco (0 bytes extra para archivos no modificados), aunque requiere más CPU para calcular metadatos.
* **El Principio 3-2-1:** Los datos viven en el disco `sda` (1), el backup local en `sdb` (2), preparándolo para un offsite mediante NFS (3).

---

## 🚀 Future Planning: Escalabilidad del Sistema

### ¿Cómo escalaría el sistema a 20 desarrolladores?
El sistema actual soportaría 20 usuarios con pequeños ajustes:
1. **Gestión de Usuarios:** La creación manual de usuarios empezaría a ser ineficiente. Se implementaría **Ansible** para automatizar el aprovisionamiento de cuentas de forma masiva.
2. **Almacenamiento:** El disco virtual de 5GB se llenaría rápido. Sería necesario migrar `/home/greendevcorp/shared` a un volumen LVM para redimensionar el disco en caliente sin apagar el servidor.
3. **Recursos:** Habría que revisar los límites PAM y Cgroups para asegurar que los 20 usuarios concurrentes no agotan la RAM física del servidor.

### ¿Cómo escalaría el sistema a 100 desarrolladores?
Para 100 personas, la arquitectura de "un solo servidor monolítico" es insostenible y un punto único de fallo (SPOF).
1. **Identidad Centralizada:** Migraríamos los usuarios locales a un servidor de identidades como **LDAP/FreeIPA** o Active Directory.
2. **Almacenamiento Desacoplado:** El directorio `/shared` pasaría a estar alojado en una red NAS (NFS) dedicada, separando la computación del almacenamiento.
3. **Entornos Efímeros:** En lugar de entrar por SSH a un servidor compartido, la infraestructura migraría a contenedores (**Docker / Kubernetes**), donde cada desarrollador levanta su entorno aislado que se destruye al terminar.