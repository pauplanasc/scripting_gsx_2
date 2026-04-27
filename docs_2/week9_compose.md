# 🐙 Week 9: Multi-Container Orchestration (Docker Compose)

## 1. Architecture & Design (Intermediate/Advanced)
Hemos diseñado una arquitectura de microservicios de 3 capas comunicadas mediante una red interna personalizada (`gsx_network`).

1. **Nginx (Reverse Proxy):** Es el punto de entrada (puerto 80). Recibe el tráfico del usuario y lo redirige internamente al backend. Es necesario porque nos permite escalar el backend en el futuro y ocultar su puerto real por seguridad.
2. **Backend (Node.js):** Contiene la lógica de la aplicación. Lee variables de entorno (`APP_MESSAGE`) y gestiona las conexiones.
3. **Redis (Database):** Base de datos en memoria ultrarrápida. Guarda el contador de visitas.

## 2. Respuestas a Conceptos Clave

**What does docker-compose.yml define?**
Es un archivo declarativo en formato YAML que define cómo debe comportarse un entorno multi-contenedor. Describe los servicios, redes, volúmenes, puertos y variables de entorno, actuando como la "receta de la orquesta".

**How do services in Compose communicate?**
Docker Compose crea un servidor DNS interno. Los contenedores no necesitan conocer sus direcciones IP; simplemente se llaman por el nombre del servicio. Por ejemplo, Nginx redirige el tráfico a `http://backend:3000`.

**Why do you need volumes? When do you use them?**
Los contenedores son efímeros; si se borran o reinician, todos sus datos internos desaparecen. Utilizamos un volumen (`redis_data`) anclado a la ruta `/data` del contenedor Redis para que el contador de visitas persista aunque destruyamos el contenedor entero.

**How do you manage secrets (API keys, passwords)?**
Nunca deben escribirse directamente (*hardcoded*) en el Dockerfile ni en el `docker-compose.yml`. Se utilizan Variables de Entorno inyectadas a través de un archivo local `.env`. El `.env` original se añade a `.gitignore` para no subirlo a GitHub, y se sube un `.env.example` con valores falsos de plantilla.

**When is Compose appropriate? When would you use Kubernetes instead?**
Compose es perfecto para desarrollo local, pruebas y servidores de producción simples (un solo nodo). Kubernetes (K8s) es necesario cuando la aplicación necesita alta disponibilidad real, escalando contenedores a través de un clúster de *múltiples* servidores físicos que se balancean entre sí.

## 3. Implementaciones Intermedias y Avanzadas
* **Health Checks & Depends_on:** Hemos configurado `condition: service_healthy`. Nginx no arrancará hasta que el Backend diga "estoy vivo", y el Backend no arrancará hasta que Redis responda a los pings. Esto evita errores de inicio (*Race Conditions*).
* **Restart Policies:** Se ha aplicado `restart: always` para que, en caso de caída del proceso o reinicio del servidor físico, el stack entero vuelva a levantarse solo.