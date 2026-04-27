#!/bin/bash
# 01_setup_base.sh
# Propósito: Instalar paquetes base y asegurar el entorno.
# Idempotencia: apt-get es nativamente idempotente.

set -euo pipefail

echo ">>> Iniciando configuración base del sistema..."

# Evitar prompts interactivos durante la instalación
export DEBIAN_FRONTEND=noninteractive

# 1. Actualizar repositorios y sistema
echo "Actualizando sistema..."
apt-get update && apt-get upgrade -y

# 2. Definir lista de paquetes necesarios
PACKAGES=(
    "git"
    "vim"
    "curl"
    "ufw"           # Firewall
    "fail2ban"      # Protección contra fuerza bruta
    "sudo"
    "openssh-server"
    "htop"
    "net-tools"
)

# 3. Instalación
echo "Instalando paquetes: ${PACKAGES[*]}"
apt-get install -y "${PACKAGES[@]}"

echo ">>> Configuración base completada."
