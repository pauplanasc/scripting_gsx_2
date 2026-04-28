# ☸️ Week 10: Container Orchestration (Kubernetes)

Este directorio contiene la infraestructura de **GreenDevCorp** migrada a Kubernetes (K8s), implementando escalabilidad dinámica, auto-sanado (self-healing) y despliegues sin tiempo de inactividad.

## 📐 Arquitectura del Clúster
* **Minikube:** Clúster de desarrollo local de un solo nodo ejecutado sobre el motor de Docker.
* **Nginx (Frontend):** Actúa como proxy inverso. Expuesto al exterior mediante un `NodePort` (Puerto 30080).
* **Backend (Node.js):** Lógica de la aplicación con 2 réplicas para garantizar la alta disponibilidad.

---

## 📚 Explicación de Recursos Kubernetes (Deliverables)

**1. ConfigMap:**
Separa la configuración del código fuente. En lugar de quemar variables en las imágenes Docker o en los propios manifiestos de los Pods, el ConfigMap inyecta de forma segura los valores (ej. `APP_MESSAGE` y `PORT`) en los contenedores durante el arranque. Es vital para mantener la inmutabilidad de las imágenes.

**2. Deployment:**
Es un supervisor de alto nivel (Controller). No ejecutamos Pods directamente; creamos Deployments. Un Deployment define el "Estado Deseado" (ej. 2 réplicas de Node.js). Si un nodo físico cae o un contenedor muere, el Deployment se encarga de crear nuevos Pods automáticamente para mantener ese estado. También permite hacer actualizaciones (*Rolling Updates*) sin cortar el servicio a los usuarios.

**3. Service:**
Proporciona descubrimiento de red y balanceo de carga. Como los Pods son efímeros (mueren y nacen con IPs diferentes), el *Service* les asigna una IP fija y un nombre DNS estable (ej. `backend`). 
* **Comunicación Interna:** Los Pods de Nginx se comunican con los de Node llamando simplemente a `http://backend:3000`. El Service intercepta y reparte el tráfico equitativamente.
* **Acceso Externo:** Usamos un Service de tipo `NodePort` para exponer el puerto interno 80 de Nginx al puerto 30080 de la máquina física, permitiendo a los usuarios externos acceder al clúster.

---

## 📈 Comportamiento de Escalado y Auto-sanado

* **Scaling:** Al ejecutar `kubectl scale deployment nginx --replicas=3`, el Bucle de Control de K8s nota que faltan 2 réplicas para alcanzar el nuevo estado deseado. Inmediatamente programa y levanta nuevos Pods en el clúster. El *Service* detecta la aparición de estos nuevos Pods y empieza a enviarles tráfico automáticamente de forma transparente.
* **Self-Healing (Recuperación de fallos):** Si simulamos un desastre matando un Pod manualmente (`kubectl delete pod <nombre>`), K8s detecta que el número real de réplicas es inferior al declarado en el Deployment e instantáneamente crea un Pod de reemplazo para mantener la disponibilidad.

---

## 🚀 Implementaciones Intermedias (Producción)

Para garantizar la estabilidad en entornos reales, se han añadido las siguientes directivas en los manifiestos YAML:

**1. Resource Requests and Limits (CPU/Memory):**
Le indican al clúster cuántos recursos mínimos necesita un Pod para arrancar (`requests`) y cuál es su límite máximo de consumo (`limits`). Esto es crucial en producción para evitar que un contenedor con una fuga de memoria (Memory Leak) consuma toda la RAM del nodo y provoque la caída del servidor físico completo (*OOM Killed*).

**2. Liveness and Readiness Probes (Health checks):**
* **Readiness Probe:** K8s no enviará tráfico al Pod hasta que esta prueba pase con éxito. Evita enviar usuarios a un contenedor que aún está cargando librerías o conectándose a bases de datos.
* **Liveness Probe:** K8s hace "pings" constantes (ej. peticiones HTTP al puerto 3000). Si la aplicación se queda congelada y deja de responder, la prueba falla y K8s reinicia automáticamente el contenedor para revivirlo.

---

## 💡 Reflexión: ¿Cuándo usar Kubernetes?
Kubernetes vale la pena (y justifica su complejidad) cuando se tiene una arquitectura de microservicios, se necesita Alta Disponibilidad real (Zero-Downtime), balanceo de tráfico a gran escala a través de múltiples servidores físicos, o sistemas de auto-escalado basados en demanda.
Es un **"overkill"** (excesivo) para aplicaciones monolíticas simples, blogs personales o MVP iniciales donde un orquestador ligero como Docker Compose o un PaaS tradicional sería más rápido de mantener y mucho más barato.