#!/bin/bash
# verify_week12.sh
# Tests reales de NetworkPolicies. Usa solo herramientas disponibles
# en las imagenes que ya tenemos (nginx:alpine -> busybox con nc + wget).

set -uo pipefail

ENV=${1:-dev}
NS="gsx-${ENV}"
OTHER_ENV=$([ "$ENV" = "dev" ] && echo "staging" || echo "dev")
OTHER_NS="gsx-${OTHER_ENV}"

# Cambiar al directorio del script para que las rutas relativas funcionen aunque
# se invoque por ruta absoluta desde cualquier cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 Verificacion NetworkPolicies en namespace [$NS] (env=$ENV)"
echo "===================================================="

PASS=0
FAIL=0

pass() { echo "✅ PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL+1)); }

# Detectar pods
NGINX_POD=$(kubectl get pod -n "$NS" -l app=nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$NGINX_POD" ]; then
    echo "❌ ERROR: no encuentro un pod nginx en $NS. Despliega primero week_11."
    exit 1
fi

echo "🧪 Pod testbed: nginx=$NGINX_POD"
echo "----------------------------------------------------"

# --- Test 1: end-to-end externo (External -> nginx -> backend -> redis) ---
# Este test cubre 3 caminos a la vez: si responde "visitante numero: N",
# significa que el trafico externo entra a nginx, nginx llega al backend,
# y el backend llega a redis. Tres tests positivos en uno.
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc nginx-service -n "$NS" -o jsonpath='{.spec.ports[0].nodePort}')
RESPONSE=$(curl -s --max-time 5 "http://$MINIKUBE_IP:$NODE_PORT" || echo "")
if echo "$RESPONSE" | grep -q "visitante numero"; then
    pass "Flujo completo: External -> nginx -> backend -> redis"
else
    fail "Flujo completo no responde. Respuesta: ${RESPONSE:-<vacia>}"
fi

# --- Test 2: nginx -> backend explicito (debe pasar) ---
if kubectl exec -n "$NS" "$NGINX_POD" -- wget -q -T 3 -O- http://backend:3000 2>/dev/null | grep -q "Entorno"; then
    pass "nginx -> backend:3000 (autorizado)"
else
    fail "nginx -> backend:3000 deberia funcionar"
fi

# --- Test 3: nginx -> redis (debe BLOQUEAR) ---
# Usamos nc de busybox (esta en nginx:alpine). -w 2 = 2s timeout.
# Si el connect tiene exito (exit 0) la politica fallo.
if kubectl exec -n "$NS" "$NGINX_POD" -- nc -w 2 -z redis 6379 2>/dev/null; then
    fail "nginx -> redis:6379 NO deberia conectar (politica abierta)"
else
    pass "nginx -> redis:6379 bloqueado correctamente"
fi

# --- Test 4: nginx -> backend.OTHER_NS (cross-env, debe BLOQUEAR) ---
if kubectl exec -n "$NS" "$NGINX_POD" -- nc -w 2 -z "backend.${OTHER_NS}.svc.cluster.local" 3000 2>/dev/null; then
    fail "nginx -> backend.${OTHER_NS} cross-env NO deberia conectar"
else
    pass "Cross-env nginx ($NS) -> backend.${OTHER_NS} bloqueado"
fi

# --- Test 5: nginx -> Internet (debe BLOQUEAR, no hay egress fuera del ns) ---
# 1.1.1.1:443 es Cloudflare; si la politica es buena, no debemos llegar.
if kubectl exec -n "$NS" "$NGINX_POD" -- nc -w 2 -z 1.1.1.1 443 2>/dev/null; then
    fail "nginx -> 1.1.1.1:443 NO deberia conectar (egress a Internet bloqueado)"
else
    pass "nginx -> Internet (1.1.1.1:443) bloqueado"
fi

# --- Test 6: DNS funciona via FQDN (debe pasar gracias a 01-allow-dns-egress) ---
# Usamos wget al FQDN completo en lugar de nslookup: nslookup de BusyBox
# no siempre honra search domains, asi que el FQDN es mas fiable.
# Si DNS no estuviera funcionando, ningun otro test habria pasado.
if kubectl exec -n "$NS" "$NGINX_POD" -- wget -q -T 3 -O- "http://backend.${NS}.svc.cluster.local:3000" 2>/dev/null | grep -q "Entorno"; then
    pass "DNS resuelve FQDN (backend.${NS}.svc.cluster.local) y allow-dns-egress activa"
else
    fail "FQDN backend.${NS}.svc.cluster.local no resuelve o no responde"
fi

echo "----------------------------------------------------"
echo "🏁 Resumen $NS: $PASS PASS, $FAIL FAIL"

if [ "$FAIL" -eq 0 ]; then
    echo "✅ TODAS LAS POLITICAS FUNCIONAN COMO SE ESPERABA"
    echo "ℹ️  Repite con: bash $(basename "$0") $OTHER_ENV"
else
    echo "⚠️  Algun test no salio como se esperaba. Revisa la politica relacionada."
    exit 1
fi
