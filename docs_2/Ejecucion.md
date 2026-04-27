markdown_content = """# 🐳 Manual de Despliegue de Infraestructura: Semanas 8 y 9
Este manual detalla los pasos necesarios para levantar desde cero el entorno de contenedores (Docker y Docker Compose) en una máquina virtual limpia (Debian/Ubuntu).

---

## 📋 Requisitos Previos
1. Una máquina con acceso a internet.
2. Usuario con permisos de `sudo`.
3. Repositorio de GitHub clonado.

---

## 🛠️ Paso 1: Instalación de Docker (Automática)
Si la máquina es nueva, lo primero es instalar el motor de Docker. Utilizaremos el script de instalación que creamos:

```bash
# 1. Dar permisos al script
chmod +x install_docker.sh

# 2. Ejecutar con sudo
sudo ./install_docker.sh

# 3. MUY IMPORTANTE: Salir y volver a entrar en la terminal
exit