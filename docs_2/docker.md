# 🐳 Week 8: Containerization (Docker) - GreenDevCorp

## 1. Diseño y Optimización de Dockerfiles (Intermediate Level)

### Simple Application (Node.js)
* **Base Image:** Elegimos `node:20-alpine`. Alpine Linux reduce el tamaño de la imagen base de ~1GB (en versiones completas de debian/ubuntu) a apenas ~115MB.
* **Multistage Build:** Hemos separado la etapa de dependencias (`builder`) de la etapa de ejecución (`runtime`). Esto asegura que herramientas de compilación no terminen en la imagen de producción, reduciendo el tamaño y la superficie de ataque.
* **Layer Optimization (Caché):** Se copia primero el `package.json` y se ejecuta `npm install` antes de copiar el código fuente. Así, si modificamos el código (server.js), Docker usa la caché de dependencias y la compilación es instantánea.
* **Security (Non-Root):** La aplicación no corre como `root`. Hemos utilizado la instrucción `USER node` para ejecutar el proceso con privilegios mínimos, previniendo escaladas de privilegios si el contenedor es comprometido.

### Nginx Server
* **Base Image:** `nginx:alpine`, logrando una imagen final de apenas unos ~40MB frente a los ~140MB de la imagen estándar.
* **Security (Non-Root):** Nginx por defecto corre como root para poder anclarse al puerto 80. Hemos creado un `nginx.conf` personalizado para que escuche en el puerto `8080`, redirigido los archivos PID y temporales a `/tmp`, y aplicado `USER nginx`.

## 2. Respuestas a Conceptos Clave

**¿Qué es un contenedor y en qué se diferencia de una Máquina Virtual (VM)?**
Una VM virtualiza el hardware completo, incluyendo un Sistema Operativo invitado pesado y su propio kernel. Un contenedor virtualiza a nivel de Sistema Operativo; comparte el kernel de la máquina host con otros contenedores, empaquetando solo la aplicación y sus dependencias (librerías, binarios). Esto los hace arrancar en milisegundos y ser extremadamente ligeros en recursos.

**¿Qué hace un Dockerfile y por qué es importante cada línea?**
Un Dockerfile es la "receta" de Infraestructura como Código (IaC) para crear una imagen. Cada línea (`FROM`, `COPY`, `RUN`) crea una "capa" (*layer*) inmutable en el sistema de archivos superpuesto (OverlayFS). El orden es vital: los comandos que cambian con menos frecuencia (como instalar dependencias) deben ir arriba para aprovechar la caché de Docker.

**¿Por qué usar Multistage Builds?**
Porque permiten usar herramientas pesadas de desarrollo (compiladores como gcc, npm) en una primera imagen, y luego copiar *solo* el binario final compilado a una segunda imagen limpia y minúscula que se mandará a producción.

**¿Qué hace que una imagen de contenedor sea "buena"?**
1. **Pequeña:** Tarda menos en descargarse (Pull) y consume menos disco.
2. **Segura:** No se ejecuta como `root` y tiene la menor cantidad de herramientas innecesarias instaladas (menor superficie de ataque).
3. **Reproducible:** El mismo Dockerfile debe generar siempre el mismo entorno, independientemente de la máquina donde se construya.

**¿Para qué sirven los container registries (como Docker Hub)?**
Actúan como el "GitHub de las imágenes compiladas". Permiten almacenar, versionar y distribuir las imágenes para que cualquier servidor de producción pueda descargar (`docker pull`) y ejecutar la aplicación sin tener que compilarla desde el código fuente.