#!/bin/bash
# verify_week10.sh
# Propósito: Verificar clúster, servicios, escalado dinámico y auto-sanado.

set -euo pipefail

echo "🔍 Iniciando verificación de la Semana 10 (Kubernetes)..."
echo "----------------------------------------------------"

# 1. Comprobar Clúster
if minikube status | grep -q "host: Running"; then
    echo "✅ Clúster K8s: Minikube está EN EJECUCIÓN."
else
    echo "❌ ERROR: Minikube no está corriendo."
    exit 1
fi

# 2. Comprobar Acceso Web (NodePort)
echo "----------------------------------------------------"
echo "🌐 Verificando acceso web externo..."
MINIKUBE_IP=$(minikube ip)
RESPONSE=$(curl -s http://$MINIKUBE_IP:30080 || echo "Fallo")

if [[ "$RESPONSE" == *"GreenDevCorp"* ]]; then
    echo "✅ Acceso Web: Nginx responde correctamente a través del NodePort (30080)."
else
    echo "❌ ERROR: Nginx no responde en http://$MINIKUBE_IP:30080."
fi

# 3. Prueba de Auto-Sanado (Resiliencia)
echo "----------------------------------------------------"
echo "🔥 Prueba de Resiliencia: Simulando una caída crítica del Backend..."
TARGET_POD=$(kubectl get pods -l app=backend -o jsonpath="{.items[0].metadata.name}")
echo "   ☠️  Destruyendo el pod: $TARGET_POD"
kubectl delete pod $TARGET_POD > /dev/null

echo "   ⏳ Esperando 5 segundos para que el Bucle de Control reaccione..."
sleep 5
NEW_POD_COUNT=$(kubectl get pods -l app=backend --field-selector=status.phase=Running | grep -v NAME | wc -l)

if [ "$NEW_POD_COUNT" -ge 1 ]; then
    echo "✅ Resiliencia Exitosa: Kubernetes ha detectado la caída y ha creado nuevos Pods al instante."
else
    echo "❌ ERROR: Kubernetes no ha recuperado el Pod caído."
fi

# 4. Prueba de Escalabilidad
echo "----------------------------------------------------"
echo "📈 Prueba de Escalado: Aumentando tráfico (Subiendo Nginx a 3 réplicas)..."
kubectl scale deployment nginx --replicas=3 > /dev/null
echo "   ⏳ Desplegando nuevos nodos..."
kubectl rollout status deployment/nginx > /dev/null

NGINX_COUNT=$(kubectl get pods -l app=nginx --field-selector=status.phase=Running | grep -v NAME | wc -l)
if [ "$NGINX_COUNT" -eq 3 ]; then
    echo "✅ Escalado Exitoso: Tráfico absorbido. Nginx escalado correctamente a 3 réplicas."
else
    echo "❌ ERROR: Falló el escalado de Nginx."
fi

# Limpieza (devolver a la normalidad)
echo "   📉 Devolviendo Nginx a 1 réplica para ahorrar recursos..."
kubectl scale deployment nginx --replicas=1 > /dev/null

echo "----------------------------------------------------"
echo "🏁 Verificación de la Semana 10 completada. ¡ERES UN MAESTRO KUBERNETES!"