#!/bin/bash
# deploy_week11.sh
# Propósito: Setup de Terraform y Despliegue automatizado de IaC en Minikube.

set -euo pipefail

# Parámetros (por defecto usa 'dev' y 'latest' si no le pasas nada)
ENV=${1:-dev}
IMAGE_TAG=${2:-latest}

echo "🚀 Iniciando despliegue automatizado de la Semana 11 (Terraform IaC) para el entorno: [$ENV]..."

# ==========================================
# FASE 0: SETUP AUTOMÁTICO (TERRAFORM)
# ==========================================
echo "⚙️  Verificando e instalando dependencias (Terraform)..."
if ! command -v terraform &> /dev/null; then
    if [ -f "./setup_week11.sh" ]; then
        echo "📥 Terraform no detectado. Ejecutando tu script setup_week11.sh..."
        bash ./setup_week11.sh
    else
        echo "❌ ERROR: Terraform no está instalado y no se encontró setup_week11.sh."
        exit 1
    fi
else
    echo "✅ Terraform ya está instalado."
fi
echo "---------------------------------------------------------"

# ==========================================
# FASE 1: PREPARACIÓN DEL CLÚSTER
# ==========================================
echo "⚙️  Comprobando el clúster de Minikube..."
if ! minikube status >/dev/null 2>&1; then
    echo "⏳ Iniciando Minikube..."
    minikube start --driver=docker
else
    echo "✅ Minikube ya está en ejecución."
fi
echo "---------------------------------------------------------"

# ==========================================
# FASE 2: DESPLIEGUE CON INFRAESTRUCTURA COMO CÓDIGO
# ==========================================
cd terraform
echo "⚙️  Inicializando proveedor de Terraform..."
terraform init -upgrade

echo "🏗️  Aplicando infraestructura declarativa para el entorno: $ENV..."
# El flag -auto-approve hace que no te pregunte "yes" a mitad del proceso
terraform apply -var-file="environments/${ENV}.tfvars" -var="image_tag=${IMAGE_TAG}" -auto-approve

# ==========================================
# FASE 3: RESUMEN Y ACCESO
# ==========================================
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc nginx-service -n "gsx-${ENV}" -o jsonpath='{.spec.ports[0].nodePort}')

echo "========================================================="
echo "✅ ¡INFRAESTRUCTURA DE LA SEMANA 11 DESPLEGADA CON ÉXITO!"
echo "🛠️  Entorno Desplegado: $ENV"
echo "🌐 URL de acceso: http://$MINIKUBE_IP:$NODE_PORT"
echo "========================================================="