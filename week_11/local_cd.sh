#!/bin/bash
# local_cd.sh - CD Manual para aplicar IaC a Minikube

set -euo pipefail

# Comprobar argumento (dev o staging)
ENV=${1:-dev}
IMAGE_TAG=${2:-latest}

echo "🚀 Iniciando Continuous Deployment local para entorno: [$ENV] con tag [$IMAGE_TAG]"

# 1. Asegurar que Minikube corre
if ! minikube status >/dev/null 2>&1; then
    echo "Encendiendo Minikube..."
    minikube start --driver=docker
fi

# 2. Aplicar IaC con Terraform
cd terraform
echo "⚙️ Inicializando Terraform..."
terraform init -upgrade

echo "🏗️ Aplicando infraestructura declarativa..."
terraform apply -var-file="environments/${ENV}.tfvars" -var="image_tag=${IMAGE_TAG}" -auto-approve

# 3. Mostrar acceso
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc nginx-service -n "gsx-${ENV}" -o jsonpath='{.spec.ports[0].nodePort}')

echo "====================================================="
echo "✅ Despliegue en $ENV completado con éxito."
echo "🌐 URL: http://$MINIKUBE_IP:$NODE_PORT"
echo "====================================================="