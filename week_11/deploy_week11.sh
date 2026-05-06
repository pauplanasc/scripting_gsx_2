#!/bin/bash
# deploy_week11.sh
# Setup automatico (Terraform si falta) + despliegue IaC en Minikube usando workspaces.

set -euo pipefail

ENV=${1:-dev}
IMAGE_TAG=${2:-latest}

echo "🚀 Despliegue Semana 11 (Terraform IaC) entorno=[$ENV] tag=[$IMAGE_TAG]..."

# ==========================================
# FASE 0: SETUP DE TERRAFORM SI FALTA
# ==========================================
if ! command -v terraform &> /dev/null; then
    if [ -f "./setup_week11.sh" ]; then
        echo "📥 Terraform no detectado. Instalando..."
        bash ./setup_week11.sh
    else
        echo "❌ ERROR: Terraform no instalado y no se encontro setup_week11.sh."
        exit 1
    fi
else
    echo "✅ Terraform ya está instalado."
fi
echo "---------------------------------------------------------"

# ==========================================
# FASE 1: PREPARACION DEL CLUSTER
# ==========================================
if ! minikube status >/dev/null 2>&1; then
    echo "⏳ Iniciando Minikube..."
    minikube start --driver=docker
else
    echo "✅ Minikube ya está en ejecución."
fi
echo "---------------------------------------------------------"

# ==========================================
# FASE 2: APLICAR IaC CON WORKSPACE POR ENTORNO
# ==========================================
cd terraform

echo "⚙️  terraform init..."
terraform init -upgrade >/dev/null

if terraform workspace list | grep -qE "^[* ]+${ENV}$"; then
    terraform workspace select "$ENV"
else
    terraform workspace new "$ENV"
fi
echo "📦 Workspace activo: $(terraform workspace show)"

echo "🏗️  terraform apply para entorno $ENV..."
terraform apply -var-file="environments/${ENV}.tfvars" -var="image_tag=${IMAGE_TAG}" -auto-approve

# ==========================================
# FASE 3: RESUMEN Y ACCESO
# ==========================================
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc nginx-service -n "gsx-${ENV}" -o jsonpath='{.spec.ports[0].nodePort}')

echo "========================================================="
echo "✅ ¡INFRAESTRUCTURA DE LA SEMANA 11 DESPLEGADA!"
echo "🛠️  Entorno: $ENV"
echo "🌐 URL: http://$MINIKUBE_IP:$NODE_PORT"
echo "========================================================="
