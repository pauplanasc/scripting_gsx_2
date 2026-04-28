# ☸️ Week 10: Orchestration with Kubernetes

## 1. Kubernetes Resources Explained

* **ConfigMap:** Separa la configuración del código. En lugar de quemar variables en la imagen Docker, el ConfigMap inyecta valores (`APP_MESSAGE`) en los contenedores al arrancar.
* **Deployment:** Es el controlador principal. Define qué imagen usar, cuántas réplicas (copias) queremos y cómo actualizar el código sin tiempo de inactividad (*Rolling Updates*). Si un pod muere, el Deployment lo detecta y crea uno nuevo.
* **Service:** Es el balanceador de carga y router DNS interno. Como los Pods mueren y nacen con IPs diferentes constantemente, el *Service* les da una dirección IP fija y un nombre DNS estable (ej. `backend`). 

## 2. Respuestas a los Conceptos Clave



**What’s a pod? How is it different from a container?**
Un Pod es la unidad atómica más pequeña en Kubernetes. No desplegamos contenedores directamente, desplegamos Pods. Un Pod es una "envoltura" que puede contener uno o más contenedores estrechamente acoplados que comparten red y almacenamiento.

**What’s a Deployment? Why would you use it instead of running a pod directly?**
Si creas un Pod directamente y muere, se queda muerto. Un Deployment es un supervisor que asegura que el estado deseado (ej. "Quiero 3 Pods de Nginx") coincida siempre con la realidad. Se usa para auto-sanado y escalabilidad.

**How do Services work? Why do you need them for networking?**
Los servicios proveen descubrimiento de red. Nuestro `nginx` se comunica con el `backend` simplemente enviando peticiones a `http://backend:3000`. El Service de K8s intercepta esa llamada y la balancea automáticamente entre todos los Pods saludables del backend.

**What happens when you scale a deployment?**
Al ejecutar `kubectl scale`, Kubernetes se comunica con los *Worker Nodes* y comienza a descargar y arrancar nuevos Pods idénticos hasta alcanzar el número deseado. El *Service* los detecta automáticamente y empieza a enviarles tráfico sin que haya que reconfigurar nada.

**How does Kubernetes recover from failures?**
A través de un "Bucle de Control". K8s constantemente compara el "Estado Deseado" (lo que escribimos en el YAML) con el "Estado Actual". Si matamos un Pod, el Estado Actual baja a 1, el Deseado es 2, así que K8s ejecuta acciones (crear un Pod) para igualarlos.

**When is Kubernetes worth the complexity? When is it overkill?**
* **Worth it:** Cuando tienes una arquitectura de microservicios compleja, necesitas alta disponibilidad real (Zero-Downtime), balanceo de carga entre múltiples servidores físicos, y el equipo tiene los conocimientos para mantenerlo.
* **Overkill:** Para un blog personal, un MVP inicial, o una app monolítica pequeña. En esos casos, Docker Compose o un servicio PaaS (como Heroku o Vercel) es mucho más eficiente y barato.

## 3. Nivel Intermedio (Probes & Limits)

Se han añadido dos elementos vitales para producción:
* **Resource Limits/Requests:** Le decimos a K8s cuánta CPU y RAM (ej. `128Mi`) puede usar como máximo un Pod. Esto evita que un contenedor mal programado sufra una fuga de memoria y tumbe todo el servidor físico.
* **Liveness & Readiness Probes:** Kubernetes hace un "ping" HTTP al puerto 3000. 
  * *Readiness:* K8s no le enviará tráfico al Pod hasta que este responda "estoy listo". 
  * *Liveness:* Si el Pod deja de responder (ej. la app se cuelga), K8s reiniciará el contenedor automáticamente.