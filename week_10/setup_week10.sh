#!/bin/bash
# setup_week10.sh
# Propósito: Instalar las herramientas de Kubernetes en el servidor.

set -euo pipefail

echo "⚙️ Iniciando la instalación de herramientas Kubernetes..."

# 1. Instalar kubectl
if ! command -v kubectl &> /dev/null; then
    echo "📥 Descargando e instalando kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo "✅ kubectl instalado."
else
    echo "✅ kubectl ya está instalado."
fi

# 2. Instalar Minikube
if ! command -v minikube &> /dev/null; then
    echo "📥 Descargando e instalando minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    echo "✅ minikube instalado."
else
    echo "✅ minikube ya está instalado."
fi

# 3. Añadir el usuario al grupo docker (por si acaso no lo estaba)
sudo usermod -aG docker $USER

echo "🎉 Entorno Kubernetes listo. Ya puedes ejecutar deploy_week10.sh"