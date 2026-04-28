# 🐙 Week 9: Multi-Container Orchestration (Docker Compose)

Este directorio contiene la infraestructura orquestada de **GreenDevCorp**, evolucionando de contenedores individuales a un entorno multi-contenedor gestionado mediante Docker Compose.

## 📐 Arquitectura de la Solución (3 Capas)
La infraestructura se compone de tres microservicios interconectados a través de una red privada (`gsx_network`):

1. **Nginx (Proxy Inverso):** Punto de entrada público (puerto 80). Recibe las peticiones HTTP y las redirige al backend.
2. **Backend (Node.js):** Lógica de la aplicación. Lee las variables de entorno de configuración y gestiona las conexiones con la base de datos.
3. **Redis (Base de Datos):** Almacenamiento en memoria ultrarrápido para persistir el contador de visitas.

---

## 🚀 Instrucciones de Despliegue

### Requisitos Previos
* Docker y Docker Compose (v2) instalados en el servidor.
* Archivo `.env` configurado (se genera automáticamente a partir de `.env.example`).

### Opción A: Despliegue Automatizado (Recomendado)
Hemos creado un script que configura el entorno, limpia versiones anteriores y levanta la orquesta de forma segura:
```bash
chmod +x deploy_week9.sh
./deploy_week9.sh

Opción B: Comandos Manuales
Bash
# 1. Crear el archivo de variables de entorno
cp .env.example .env

# 2. Construir y levantar los contenedores en segundo plano
docker compose up -d --build

# 3. Comprobar el estado y los Healthchecks
docker compose ps

🧪 Pruebas y Verificación
Comunicación entre servicios:
Ejecuta curl http://localhost. Deberías ver un mensaje de bienvenida y un contador de visitas que incrementa con cada petición (demostrando que Nginx habla con Node, y Node habla con Redis).

Persistencia de Datos (Volúmenes):

Bash
docker compose down
docker compose up -d
curl http://localhost
Resultado esperado: El contador de visitas retiene su valor anterior y no vuelve a 1, confirmando que el volumen redis_data funciona correctamente.

Observabilidad:
Para ver los logs centralizados de toda la infraestructura:

Bash
docker compose logs --tail=20 -f
📚 Documentación y Conceptos Clave (Entregables)
1. What does docker-compose.yml define?
Es un archivo declarativo (YAML) que define la "receta" completa de nuestra infraestructura: qué contenedores se necesitan, cómo se llaman, qué puertos exponen, qué volúmenes montan y en qué orden deben arrancar.

2. How do services in Compose communicate?
Docker Compose crea un servidor DNS interno automáticamente. Los contenedores no necesitan conocer direcciones IP; se comunican utilizando el nombre del servicio definido en el YAML (ej. Nginx redirige tráfico internamente a http://backend:3000).

3. Why do you need volumes? When do you use them?
Los contenedores son efímeros por diseño; si se destruyen, toda su información interna desaparece. Utilizamos un volumen (redis_data) mapeado al directorio /data de Redis para que los datos persistan independientemente del ciclo de vida del contenedor. Se usan siempre que se manejan bases de datos o archivos subidos por usuarios.

4. How do you manage secrets (API keys, passwords)?
Nunca deben escribirse (hardcoded) en el Dockerfile o en el docker-compose.yml. Utilizamos un archivo local .env que Docker Compose lee automáticamente para inyectar las Variables de Entorno. Este archivo .env se añade al .gitignore para no comprometer credenciales en el repositorio, subiendo únicamente una plantilla .env.example.

5. When is Compose appropriate? When would you use Kubernetes instead?
Compose es ideal para entornos de desarrollo local, pruebas (CI/CD) y despliegues de producción simples en un único servidor (mononodo). Se debe migrar a Kubernetes (K8s) cuando la aplicación requiere alta disponibilidad real (escalar réplicas a través de un clúster de múltiples servidores físicos), auto-sanado avanzado y balanceo de carga distribuido.

🔥 Funcionalidades Avanzadas Implementadas
Healthchecks: Se han configurado comandos internos para verificar que los servicios están listos antes de recibir tráfico.

Dependencias (depends_on): El Backend espera a que Redis esté service_healthy, y Nginx espera al Backend, evitando errores de arranque (Race Conditions).

Políticas de Reinicio (restart: always): Garantiza que la infraestructura se recupere automáticamente tras un reinicio del servidor físico o una caída del proceso.