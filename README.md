# 🚀 GreenDevCorp - Infraestructura como Código (IaC)

Bienvenido al repositorio de infraestructura de GreenDevCorp. Este proyecto contiene la automatización completa para desplegar un servidor de desarrollo seguro, escalable y monitorizado basado en Debian 12, utilizando únicamente scripts de Bash y herramientas nativas de Linux.

## 📂 Estructura del Repositorio

* `/week_1`: Configuración base (Usuarios, SSH, Firewall UFW).
* `/week_2`: Despliegue de servicios (Nginx) y auto-recuperación (Systemd).
* `/week_3`: Gestión de recursos (Cgroups) y monitorización de procesos.
* `/week_4`: Entorno colaborativo seguro (SGID, Sticky Bits, PAM limits).
* `/week_5`: Almacenamiento (ext4, fstab) y copias de seguridad incrementales (Rsync).
* `/docs`: Documentación técnica, Runbooks y Diseño de Arquitectura.
* `bootstrap.sh`: Script semilla para el despliegue automatizado "One-Click".

## 🛠️ Cómo desplegar desde cero (Quickstart)

Si tienes un servidor Debian 12 completamente limpio, puedes levantar toda la infraestructura ejecutando este único comando como usuario `root`:

\`\`\`bash
curl -sL https://raw.githubusercontent.com/TU_USUARIO/scripting_gsx/main/bootstrap.sh | bash
\`\`\`
*(Nota: Cambia TU_USUARIO por tu usuario real de GitHub).*

## 📖 Documentación del Sistema

Toda la documentación operativa y de diseño se encuentra en la carpeta `/docs`:
* [📘 Manual de Operaciones (Runbook)](docs/runbook.md)
* [🏗️ Diseño de Arquitectura y Escalabilidad](docs/architecture.md)
* [🚑 Recuperación de Desastres](docs/disaster_recovery.md)
* [🧠 Ensayo de Reflexión](docs/reflection.md)

