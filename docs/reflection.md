# 🧠 Ensayo de Reflexión del Equipo (Reflection Essay)

**Equipo:** Pau Planas y Jesus Martinez  
**Proyecto:** Infraestructura y Servidor de Desarrollo - GreenDevCorp  

---

### 1. What was the most challenging aspect of this project?
> *¿Cuál fue el aspecto más desafiante de este proyecto?*

Sin duda, nuestro mayor reto conjunto fue enfrentarnos al **"problema del huevo y la gallina"** en la automatización inicial y comprender la gestión de permisos a bajo nivel. 

Durante el desarrollo, nos topamos con bloqueos críticos de los que era difícil salir: al intentar ejecutar la orquestación en una máquina virtual limpia, llegamos a perder los permisos de administrador (el temido error *"user NOT in sudoers"* y la pérdida de control sobre `su`). 

Solucionar esto nos obligó a salir de nuestra zona de confort como equipo. Tuvimos que aprender a intervenir el proceso de arranque de Linux (GRUB), investigar cómo inyectar un entorno de rescate y lidiar con los identificadores criptográficos cambiantes de SSH (alertas de *"Man-in-the-middle"*) al restaurar *snapshots* en VirtualBox. Fueron errores frustrantes, pero debatir y aplicar la solución juntos lo hizo tremendamente educativo.

### 2. What would you do differently if you started over?
> *¿Qué haríais diferente si volvierais a empezar?*

Si empezáramos el proyecto desde cero, adoptaríamos un enfoque de **programación mucho más defensiva**:

* **Idempotencia desde el día 1:** Al principio asumíamos que herramientas como `rsync` o ciertos comandos del sistema siempre estarían disponibles. Ahora entendemos que nuestros scripts deben comprobar proactivamente si una dependencia existe antes de intentar usarla o instalarla, evitando que el script se rompa a la mitad.
* **Automatización del despliegue base:** Implementaríamos el script `bootstrap.sh` mucho antes en la fase de diseño. Tener un único comando para descargar dependencias, clonar el repositorio de GitHub y lanzar la Semana 1 nos habría ahorrado horas de configuraciones repetitivas a mano en cada nueva prueba.

### 3. How has your understanding of system administration changed?
> *¿Cómo ha cambiado vuestra comprensión de la administración de sistemas?*

Antes de este proyecto, veíamos la administración de sistemas como la tarea reactiva de memorizar comandos aislados y "apagar incendios" manualmente en la terminal. Ahora hemos interiorizado el paradigma de la **Infraestructura como Código (IaC)** y el concepto de *Cattle vs. Pets* (Ganado vs. Mascotas).

Hemos comprendido que un servidor no es una máquina a la que hay que cuidar con mimo a mano; si nuestro entorno de producción se corrompe, no debemos pasar 5 horas arreglándolo. Simplemente lo destruimos, levantamos una máquina limpia y ejecutamos nuestro repositorio para levantar un clon exacto en minutos. Además, hemos descubierto que un sistema sin una buena observabilidad (Systemd Timers, límites Cgroups, monitorización de logs) es una caja negra muy peligrosa.

### 4. What’s one thing you’d want to learn more about?
> *¿Sobre qué aspecto os gustaría aprender más?*

Nos encantaría profundizar en la **orquestación y escalabilidad a gran escala**. 

Aunque Bash y Shell Scripting nos han dado una base fundamental y potentísima para entender las entrañas del kernel de Linux, los permisos y los servicios, hemos notado sus limitaciones si tuviéramos que escalar esta misma infraestructura a 100 servidores simultáneos. 

Nuestro siguiente paso natural sería aprender herramientas de configuración declarativa como **Ansible** o **Terraform** para aprovisionar flotas enteras de máquinas, o explorar la contenerización con **Docker** y **Kubernetes** para independizar totalmente los entornos de desarrollo del sistema operativo base.