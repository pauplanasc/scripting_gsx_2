#!/bin/bash
# local_cd.sh - CD manual a Minikube usando Terraform workspaces (uno por entorno)

set -euo pipefail

ENV=${1:-dev}
IMAGE_TAG=${2:-latest}

echo "🚀 Continuous Deployment local: entorno=[$ENV] tag=[$IMAGE_TAG]"

# 1. Asegurar Minikube
if ! minikube status >/dev/null 2>&1; then
    echo "⏳ Iniciando Minikube..."
    minikube start --driver=docker
fi

cd terraform

# 2. Init
echo "⚙️  terraform init..."
terraform init -upgrade >/dev/null

# 3. Workspace por entorno (estado aislado: dev y staging pueden convivir)
terraform workspace select "$ENV" 2>/dev/null || terraform workspace new "$ENV"
echo "📦 Workspace activo: $(terraform workspace show)"

# 4. Apply
echo "🏗️  terraform apply..."
terraform apply -var-file="environments/${ENV}.tfvars" -var="image_tag=${IMAGE_TAG}" -auto-approve

# 5. Reportar URL
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc nginx-service -n "gsx-${ENV}" -o jsonpath='{.spec.ports[0].nodePort}')

echo "====================================================="
echo "✅ Despliegue en $ENV completado."
echo "🌐 URL: http://$MINIKUBE_IP:$NODE_PORT"
echo "====================================================="
