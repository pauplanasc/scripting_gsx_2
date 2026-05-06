#!/bin/bash
# deploy_week12.sh
# Aplica las NetworkPolicies de la Semana 12 sobre los namespaces ya existentes
# de la Semana 11 (gsx-dev y gsx-staging).
# REQUISITO: Minikube tiene que estar arrancado con un CNI que soporte
# NetworkPolicies (Calico o Cilium). El kindnet por defecto las IGNORA.

set -euo pipefail

NAMESPACES="gsx-dev gsx-staging"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICIES_DIR="$SCRIPT_DIR/networkpolicies"

echo "🚀 Desplegando NetworkPolicies (Semana 12)..."
echo "----------------------------------------------------"

# 0. Sanity check: avisamos si el CNI no aplica NetworkPolicies
CNI_INFO=$(kubectl get pods -n kube-system 2>/dev/null | grep -E "calico|cilium" || echo "")
if [ -z "$CNI_INFO" ]; then
    echo "⚠️  AVISO: no detecto Calico/Cilium en kube-system."
    echo "    Si usas el CNI por defecto de Minikube (kindnet), las NetworkPolicies"
    echo "    se aceptan pero NO se aplican. Reinicia con: minikube delete && minikube start --cni=calico"
    echo ""
fi

# 1. Etiquetar los namespaces (util para futuros namespaceSelector)
for ns in $NAMESPACES; do
    env_label=$(echo "$ns" | sed 's/gsx-//')
    kubectl label namespace "$ns" environment="$env_label" --overwrite >/dev/null
    echo "🏷️  Namespace $ns etiquetado: environment=$env_label"
done
echo "----------------------------------------------------"

# 2. Aplicar las politicas activas (00-04) a cada namespace
ACTIVE_POLICIES=(
    "00-default-deny.yaml"
    "01-allow-dns-egress.yaml"
    "02-nginx-policies.yaml"
    "03-backend-policies.yaml"
    "04-redis-policies.yaml"
)

for ns in $NAMESPACES; do
    echo "📦 Aplicando politicas a $ns..."
    for policy in "${ACTIVE_POLICIES[@]}"; do
        kubectl apply -n "$ns" -f "$POLICIES_DIR/$policy"
    done
done
echo "----------------------------------------------------"

# 3. Resumen
for ns in $NAMESPACES; do
    echo "📋 NetworkPolicies en $ns:"
    kubectl get networkpolicy -n "$ns" --no-headers
    echo ""
done

echo "====================================================="
echo "✅ Despliegue de NetworkPolicies completado."
echo "ℹ️  La politica 05-partners-cidr-restricted.yaml NO se aplica:"
echo "    es demostrativa (vease docs_2/week12_documentation.md)."
echo "====================================================="
