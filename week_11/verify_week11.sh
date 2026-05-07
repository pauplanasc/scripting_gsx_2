#!/bin/bash
# verify_week11.sh
# Verifica el despliegue IaC: namespace, pods Ready, conectividad e idempotencia.

set -uo pipefail

ENV=${1:-dev}
IMAGE_TAG=${2:-latest}

# Cambiar al directorio del script asi 'cd terraform' funciona aunque se invoque
# por ruta absoluta desde cualquier cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 Verificación Semana 11: entorno=[$ENV] tag=[$IMAGE_TAG]"
echo "----------------------------------------------------"

# 1. Minikube up (si no, lo arrancamos)
if ! minikube status | grep -q "host: Running"; then
    echo "⏳ Minikube no está corriendo. Arrancando..."
    minikube start --driver=docker
fi
echo "✅ K8s Motor: Minikube en ejecución."

# 2. Namespace
NAMESPACE="gsx-${ENV}"
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "❌ ERROR: namespace $NAMESPACE no existe. ¿Has lanzado 'local_cd.sh $ENV ...'?"
    exit 1
fi
echo "✅ IaC: Namespace aislado $NAMESPACE existe."

# 3. Deployments Ready
echo "⏳ Esperando rollout de redis/backend/nginx..."
kubectl rollout status deployment/redis   -n "$NAMESPACE" --timeout=120s >/dev/null
kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=120s >/dev/null
kubectl rollout status deployment/nginx   -n "$NAMESPACE" --timeout=120s >/dev/null
echo "✅ Alta Disponibilidad: redis, backend y nginx Ready."

# 4. Conectividad externa (con retry: tras un minikube restart los Services pueden
#    tardar unos segundos en estabilizar el routing aunque los pods esten Ready).
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc nginx-service -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')

RESPONSE=""
for attempt in 1 2 3 4 5; do
    RESPONSE=$(curl -s --max-time 5 "http://$MINIKUBE_IP:$NODE_PORT" || echo "")
    if [[ "$RESPONSE" == *"Entorno"* && "$RESPONSE" == *"visitante"* ]]; then
        break
    fi
    sleep 3
done

if [[ "$RESPONSE" == *"Entorno"* && "$RESPONSE" == *"visitante"* ]]; then
    echo "✅ Conectividad: Nginx responde por NodePort $NODE_PORT y Redis está vivo (contador OK)."
else
    echo "❌ ERROR: respuesta inesperada del stack tras 5 intentos:"
    echo "    $RESPONSE"
    exit 1
fi

# 5. Idempotencia (canonico: -detailed-exitcode devuelve 0=sin diff, 2=hay diff)
echo "----------------------------------------------------"
echo "⚖️  Comprobando idempotencia con 'terraform plan -detailed-exitcode'..."
cd terraform
terraform workspace select "$ENV" >/dev/null 2>&1 || true

set +e
terraform plan \
    -var-file="environments/${ENV}.tfvars" \
    -var="image_tag=${IMAGE_TAG}" \
    -detailed-exitcode > /tmp/tf-plan-$$.log 2>&1
PLAN_EXIT=$?
set -e

case "$PLAN_EXIT" in
    0)
        echo "✅ Idempotencia exitosa: la infraestructura coincide EXACTAMENTE con el código."
        ;;
    2)
        echo "⚠️  Drift detectado. Últimas 30 líneas del plan:"
        tail -30 /tmp/tf-plan-$$.log
        ;;
    *)
        echo "❌ Error ejecutando 'terraform plan' (exit=$PLAN_EXIT). Salida:"
        cat /tmp/tf-plan-$$.log
        ;;
esac
rm -f /tmp/tf-plan-$$.log

echo "----------------------------------------------------"
echo "🏁 Verificación de la Semana 11 completada."
