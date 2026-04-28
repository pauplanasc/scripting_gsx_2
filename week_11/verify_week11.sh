#!/bin/bash
# verify_week11.sh
# Propósito: Verificar el despliegue de IaC, Namespaces y la Idempotencia de Terraform.

set -euo pipefail

ENV=${1:-dev}

echo "🔍 Iniciando verificación de la Semana 11 para el entorno: [$ENV]..."
echo "----------------------------------------------------"

# 1. Comprobar motor de K8s
if minikube status | grep -q "host: Running"; then
    echo "✅ K8s Motor: Minikube está EN EJECUCIÓN."
else
    echo "❌ ERROR: Minikube no está corriendo."
    exit 1
fi

# 2. Comprobar Namespace dinámico creado por Terraform
NAMESPACE="gsx-${ENV}"
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "✅ IaC: Terraform ha creado correctamente el Namespace aislado: $NAMESPACE"
else
    echo "❌ ERROR: El Namespace $NAMESPACE no existe. Terraform falló."
    exit 1
fi

# 3. Comprobar salud de los Pods dentro del Namespace
echo "⏳ Esperando a que los Pods de $ENV estén listos..."
kubectl rollout status deployment/backend -n "$NAMESPACE" >/dev/null 2>&1
kubectl rollout status deployment/nginx -n "$NAMESPACE" >/dev/null 2>&1
echo "✅ Alta Disponibilidad: Los Pods de Backend y Nginx están corriendo sin errores."

# 4. Comprobar Acceso Web Real
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc nginx-service -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
RESPONSE=$(curl -s http://$MINIKUBE_IP:$NODE_PORT || echo "Fallo")

if [[ "$RESPONSE" == *"GreenDevCorp"* || "$RESPONSE" == *"Entorno"* ]]; then
    echo "✅ Conectividad: Nginx responde correctamente al exterior (Puerto $NODE_PORT)."
else
    echo "❌ ERROR: Fallo de red. Nginx no responde."
fi

# 5. La prueba definitiva: Idempotencia de IaC
echo "----------------------------------------------------"
echo "⚖️  Comprobando Idempotencia del Código Terraform..."
cd terraform
if terraform plan -var-file="environments/${ENV}.tfvars" -var="image_tag=latest" | grep -q "No changes."; then
    echo "✅ Idempotencia Exitosa: La infraestructura física coincide EXACTAMENTE con el código."
else
    echo "⚠️  Aviso: Terraform detectó diferencias entre el código y la realidad."
fi

echo "----------------------------------------------------"
echo "🏁 Verificación de la Semana 11 completada. ¡ERES UN DIOS DEL DEVOPS!"