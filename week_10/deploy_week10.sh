#!/bin/bash
# deploy_week10.sh
# Propósito: Automatizar la preparación y el despliegue en Kubernetes (Minikube).

set -euo pipefail

echo "🚀 Iniciando despliegue automatizado de la Semana 10 (Kubernetes)..."

# 1. Liberar Memoria RAM (Vital para Minikube)
echo "🧹 Apagando infraestructura de la Semana 9 para liberar RAM..."
if [ -d "../week_9" ]; then
    (cd ../week_9 && docker compose down 2>/dev/null || true)
fi

# 2. Iniciar Minikube si no está encendido
echo "⚙️  Comprobando el clúster de Minikube..."
if ! minikube status >/dev/null 2>&1; then
    echo "⏳ Iniciando Minikube (esto puede tardar 1 o 2 minutos)..."
    minikube start --driver=docker
else
    echo "✅ Minikube ya está en ejecución."
fi

# 3. Aplicar manifiestos
echo "🏗️  Aplicando manifiestos YAML (ConfigMap, Deployments, Services)..."
kubectl apply -f kubernetes/

# 4. Esperar a que la infraestructura esté lista (Readiness Probes)
echo "⏳ Esperando a que Kubernetes declare los Pods como 'Listos'..."
kubectl rollout status deployment/backend
kubectl rollout status deployment/nginx

# 5. Resumen final
echo "📊 Estado final de los Pods:"
kubectl get pods

MINIKUBE_IP=$(minikube ip)
echo "========================================================="
echo "✅ ¡INFRAESTRUCTURA DE LA SEMANA 10 DESPLEGADA CON ÉXITO!"
echo "👉 Prueba tu web externa ejecutando:"
echo "   curl http://$MINIKUBE_IP:30080"
echo "========================================================="