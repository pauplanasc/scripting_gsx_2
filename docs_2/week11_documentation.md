# 🏗️ Week 11: Infrastructure as Code & CI/CD

## 1. Conceptos Clave y Tooling

**What’s Infrastructure as Code? Why does it matter?**
IaC significa escribir código legible por humanos y máquinas (ej. HCL o YAML) que define y aprovisiona la infraestructura. Es vital porque elimina el "error humano" de hacer clics manuales o lanzar comandos sueltos, permite versionar la infraestructura (saber quién cambió qué y cuándo) y hace que los entornos sean 100% reproducibles desde cero en minutos.

**Terraform (Declarative) vs. Ansible (Procedural)**
* Hemos elegido **Terraform** porque es **Declarativo**. Tú le dices "Quiero 3 servidores y una red", y Terraform averigua *cómo* hacerlo. Si la red ya existe, no la vuelve a crear.
* **Ansible** (aunque puede ser idempotente) es inherentemente **Procedural**. Le das instrucciones paso a paso: "Crea el servidor 1, crea la red 2, conecta esto con aquello". Terraform es el estándar para *crear* recursos en K8s y Cloud, mientras que Ansible es mejor para *configurar* sistemas operativos por dentro.

**What does a CI/CD pipeline do?**
* **CI (Continuous Integration):** Se dispara automáticamente. En nuestro caso (GitHub Actions), cada `git push` compila el código, crea las imágenes Docker inmutables, las sube al Registry (DockerHub) etiquetadas con el SHA del commit, y valida la sintaxis de Terraform (`terraform validate`).
* **CD (Continuous Deployment/Delivery):** Es el proceso de coger ese artefacto validado y aplicarlo en el entorno final (Minikube). 

## 2. Flujo de Trabajo (End-to-End)
Nuestro flujo de trabajo resuelve la limitación de que GitHub Actions no puede acceder a nuestro Minikube local:
1.  **Code & Push:** Un desarrollador modifica la app en `week_9/backend/server.js` y hace un `git push`.
2.  **CI Pipeline (GitHub):** Actions detecta el push, construye la nueva imagen Docker (`pauplanasc/simple-app-gsx:a1b2c3d`) y la sube a DockerHub. Verifica que el código `.tf` no tiene errores de sintaxis.
3.  **Local CD (Máquina Local):** El SysAdmin abre la terminal y ejecuta `./local_cd.sh staging a1b2c3d`. Terraform lee el estado actual de Minikube, nota que la versión de la imagen ha cambiado, y actualiza el Deployment en Kubernetes sin cortes de servicio.

## 3. Multiple Environments (Intermediate)
En lugar de copiar y pegar manifiestos YAML enteros, usamos **Terraform Variables (`.tfvars`)**.
* Con un solo código base (`main.tf`), podemos desplegar una versión barata y con mensajes de depuración ejecutando `-var-file="environments/dev.tfvars"`.
* Para asegurar que *staging* funciona antes de producción, aplicamos exactamente el mismo código base, pero inyectando `staging.tfvars` (que despliega más réplicas en un Namespace K8s separado, simulando carga de producción real).