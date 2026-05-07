#!/bin/bash
# integration_test.sh - Challenge B (Required) Semana 13
# Test de integracion full: destruye TODO, redespliega desde cero usando IaC,
# y verifica end-to-end (semana 11 + semana 12). Demuestra que la infraestructura
# es 100% reproducible desde codigo y que los componentes encajan.

set -uo pipefail

IMAGE_TAG=${1:-4d169be}
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$REPO_ROOT/week_11/terraform"
START=$(date +%s)

echo "🧪 INTEGRATION TEST - Semana 13"
echo "   Image tag: $IMAGE_TAG"
echo "   Repo:      $REPO_ROOT"
echo "===================================================="

# ----------------------------------------------------
# FASE 1: estado inicial
# ----------------------------------------------------
echo ""
echo "📊 FASE 1 - Estado inicial"
echo "----------------------------------------------------"
minikube status >/dev/null 2>&1 || { echo "⏳ Minikube parado, arrancando..."; minikube start; }
echo "✅ Minikube activo"
echo ""
echo "Namespaces actuales con prefijo gsx-:"
kubectl get ns | grep gsx- || echo "  (ninguno)"

# ----------------------------------------------------
# FASE 2: destruir TODO (dev + staging) via IaC
# ----------------------------------------------------
echo ""
echo "💥 FASE 2 - Destruccion via terraform destroy en cada workspace"
echo "----------------------------------------------------"
cd "$TF_DIR"
terraform init -upgrade >/dev/null

for env in dev staging; do
    if terraform workspace select "$env" 2>/dev/null; then
        echo "🔥 Destruyendo workspace=$env..."
        terraform destroy \
            -var-file="environments/${env}.tfvars" \
            -var="image_tag=${IMAGE_TAG}" \
            -auto-approve >/dev/null 2>&1 || true
        echo "✅ workspace=$env destruido"
    else
        echo "ℹ️  workspace=$env no existe, salto destroy"
    fi
done

# Verificar que los namespaces se han ido
echo ""
echo "🔎 Verificacion de limpieza:"
remaining=$(kubectl get ns 2>/dev/null | grep -c "gsx-" || true)
if [ "$remaining" -eq 0 ]; then
    echo "✅ Cluster limpio (cero namespaces gsx-)"
else
    echo "⚠️  Aun quedan $remaining namespace(s) gsx-, sigo de todas formas"
fi

# ----------------------------------------------------
# FASE 3: redespliegue desde cero
# ----------------------------------------------------
echo ""
echo "🚀 FASE 3 - Redespliegue desde IaC"
echo "----------------------------------------------------"
cd "$REPO_ROOT/week_11"

T_DEV_START=$(date +%s)
echo "📦 Desplegando dev..."
bash local_cd.sh dev "$IMAGE_TAG" >/tmp/integration-dev.log 2>&1
T_DEV_END=$(date +%s)
DEV_TIME=$((T_DEV_END - T_DEV_START))
echo "✅ dev desplegado en ${DEV_TIME}s"

T_STG_START=$(date +%s)
echo "📦 Desplegando staging..."
bash local_cd.sh staging "$IMAGE_TAG" >/tmp/integration-staging.log 2>&1
T_STG_END=$(date +%s)
STG_TIME=$((T_STG_END - T_STG_START))
echo "✅ staging desplegado en ${STG_TIME}s"

# ----------------------------------------------------
# FASE 4: aplicar NetworkPolicies
# ----------------------------------------------------
echo ""
echo "🛡️  FASE 4 - Aplicando NetworkPolicies (Semana 12)"
echo "----------------------------------------------------"
cd "$REPO_ROOT/week_12"
T_NP_START=$(date +%s)
bash deploy_week12.sh >/tmp/integration-np.log 2>&1
T_NP_END=$(date +%s)
NP_TIME=$((T_NP_END - T_NP_START))
echo "✅ NetworkPolicies aplicadas en ${NP_TIME}s"

# ----------------------------------------------------
# FASE 5: verificacion end-to-end
# ----------------------------------------------------
echo ""
echo "🔬 FASE 5 - Verificacion end-to-end"
echo "----------------------------------------------------"

cd "$REPO_ROOT/week_11"
echo "▶️  verify_week11.sh dev $IMAGE_TAG"
bash verify_week11.sh dev "$IMAGE_TAG" 2>&1 | tail -25
echo ""
echo "▶️  verify_week11.sh staging $IMAGE_TAG"
bash verify_week11.sh staging "$IMAGE_TAG" 2>&1 | tail -25

cd "$REPO_ROOT/week_12"
echo ""
echo "▶️  verify_week12.sh dev"
bash verify_week12.sh dev 2>&1 | grep -E "PASS|FAIL|🏁|✅ TODAS|⚠️"
echo ""
echo "▶️  verify_week12.sh staging"
bash verify_week12.sh staging 2>&1 | grep -E "PASS|FAIL|🏁|✅ TODAS|⚠️"

# ----------------------------------------------------
# FASE 6: resumen
# ----------------------------------------------------
END=$(date +%s)
TOTAL=$((END - START))

echo ""
echo "===================================================="
echo "📈 RESUMEN INTEGRATION TEST"
echo "----------------------------------------------------"
echo "   Tiempo destroy + apply dev:    ${DEV_TIME}s"
echo "   Tiempo apply staging:          ${STG_TIME}s"
echo "   Tiempo NetworkPolicies:        ${NP_TIME}s"
echo "   Tiempo total:                  ${TOTAL}s"
echo ""
echo "   URLs de acceso:"
DEV_PORT=$(kubectl get svc nginx-service -n gsx-dev -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "?")
STG_PORT=$(kubectl get svc nginx-service -n gsx-staging -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "?")
MIP=$(minikube ip)
echo "   dev:     http://$MIP:$DEV_PORT"
echo "   staging: http://$MIP:$STG_PORT"
echo "===================================================="
echo ""
echo "ℹ️  Logs detallados en /tmp/integration-*.log"
echo "🏁 Integration test completado."
