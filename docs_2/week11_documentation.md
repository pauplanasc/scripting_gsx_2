# Week 11: Infrastructure as Code & CI/CD

## 1. Conceptos clave

### What is Infrastructure as Code? Why does it matter?
IaC consiste en describir la infraestructura mediante código versionable (en nuestro caso HCL de Terraform) en vez de hacerlo a base de clics o `kubectl apply` manuales. Importa por tres motivos: **reproducibilidad** (un compañero clona el repo y levanta el stack idéntico), **trazabilidad** (cada cambio queda en `git log` con autor y fecha) y **fiabilidad** (el plan se revisa antes de aplicarse, evitando errores manuales).

### Terraform (declarative) vs. Ansible (procedural)
- **Terraform** (elegido) es **declarativo**: describes el estado deseado (`replica_count = 2`, `namespace = "gsx-dev"`) y Terraform calcula el diff con el estado real para aplicarlo. Si los recursos ya existen como tú quieres, no hace nada (idempotencia natural).
- **Ansible** es **procedural**: escribes pasos ordenados. Es más fuerte en configuración del SO de un host (instalar paquetes, copiar archivos), pero más débil para crear y mantener grafos de recursos en K8s.

Para este caso (crear y mantener recursos K8s sobre Minikube) Terraform encaja mejor: el provider `hashicorp/kubernetes` mapea 1-a-1 con la API de Kubernetes y nos da un `terraform plan` que muestra exactamente qué va a cambiar.

### What does a CI/CD pipeline do?
- **CI** (en GitHub Actions): cada `push` a `main` construye las imágenes Docker (backend y nginx), las publica en Docker Hub con dos tags (`<commit-sha>` y `latest`) y valida el código Terraform (`fmt`, `init -backend=false`, `validate`).
- **CD** (local): el ingeniero ejecuta `bash local_cd.sh <env> <tag>` en su máquina, Terraform compara el estado real de Minikube con el deseado y aplica solo el delta (típicamente, cambiar el `image_tag` del Deployment).

Separamos CI y CD por una restricción real del enunciado: **GitHub Actions no tiene acceso al Minikube local**, así que el "deploy" lo lanzamos a mano contra el cluster de la VM.

## 2. Estructura del código

```
scripting_gsx_2/
├── .github/workflows/ci.yml       # Workflow de GitHub Actions (DEBE estar en raíz)
└── week_11/
    ├── terraform/
    │   ├── providers.tf           # Provider hashicorp/kubernetes apuntando a minikube
    │   ├── variables.tf           # environment, app_message, image_tag, replica_count
    │   ├── main.tf                # Namespace, ConfigMap, Redis, Backend, Nginx (+ Services)
    │   ├── outputs.tf             # namespace, image_tag, replicas, NodePort, access_hint
    │   └── environments/
    │       ├── dev.tfvars         # 1 replica, mensaje "DESARROLLO"
    │       └── staging.tfvars     # 2 replicas, mensaje "STAGING"
    ├── deploy_week11.sh           # Setup completo (instala terraform si falta) + apply
    ├── local_cd.sh                # Solo apply (asume terraform ya instalado)
    └── verify_week11.sh           # Comprueba namespace, pods Ready, curl OK e idempotencia
```

> **Nota importante**: GitHub Actions sólo detecta workflows en `.github/workflows/` desde la **raíz del repositorio**. Por eso este archivo NO puede vivir dentro de `week_11/.github/`. Las rutas internas del workflow (`./week_9/backend`, `./week_11/terraform`, etc.) son relativas a la raíz.

### Variables (`variables.tf`)
| Variable | Tipo | Por qué |
|---|---|---|
| `environment` | string | Nombre del entorno; se usa para construir el namespace `gsx-${environment}` |
| `app_message` | string | Mensaje servido por el backend (inyectado vía ConfigMap) |
| `image_tag` | string (default `latest`) | Tag Docker; en CD lo pasamos al SHA del commit que produjo la CI |
| `replica_count` | number | Réplicas del backend; permite simular carga en staging |

### Outputs (`outputs.tf`)
- `namespace`: el namespace creado (útil para `kubectl -n <ns>`).
- `image_tag_deployed`: deja constancia de qué tag está corriendo realmente.
- `backend_replicas`: feedback inmediato del fan-out.
- `nginx_node_port`: el puerto que Minikube ha asignado.
- `access_hint`: comando listo para copiar/pegar y obtener la URL.

## 3. Cómo desplegar (paso a paso)

### Despliegue desde cero
```bash
# 1. (Local CD) Levantar Minikube y aplicar IaC
cd ~/scripting_gsx_2/week_11
bash deploy_week11.sh dev latest         # entorno dev con tag :latest
# o:
bash deploy_week11.sh staging <sha7>     # entorno staging con un SHA específico

# 2. Verificar
bash verify_week11.sh dev
```

### Despliegue tras un cambio de código
1. Modificas algo en `week_9/backend/server.js` (o `Dockerfile`, o `main.tf`).
2. `git push origin main`.
3. La CI construye y publica `pauplanasc/simple-app-gsx:<sha>` y `:latest`.
4. Cuando la CI esté en verde, desde la VM:
   ```bash
   bash local_cd.sh dev <sha7>
   ```
   Terraform detecta que el `image` del Deployment ha cambiado y hace un rolling update.

### Cómo se elige el image tag
La CI publica **dos tags** por imagen: el SHA corto del commit (inmutable, ideal para reproducibilidad) y `latest` (cómodo para pruebas rápidas). El SHA se calcula con `git rev-parse --short HEAD` en el step "Set Image Tag". En el CD lo pasamos como `-var="image_tag=<sha>"`, que sustituye `${var.image_tag}` en el atributo `image` de los `kubernetes_deployment`.

## 4. Multiple Environments (Intermediate **)

Mantenemos **un único `main.tf`** y parametrizamos las diferencias en `environments/<env>.tfvars`:

| | dev | staging |
|---|---|---|
| Namespace | `gsx-dev` | `gsx-staging` |
| Réplicas backend | 1 | 2 |
| Mensaje | "Entorno de DESARROLLO (Inestable)" | "Entorno de STAGING (Copia exacta de Prod)" |

Esto evita el anti-patrón de copiar y pegar manifiestos: si añades un recurso, se aplica a todos los entornos automáticamente.

### Aislamiento de estado: Terraform Workspaces

Compartir un único `terraform.tfstate` entre entornos es un anti-patrón: cuando cambias `environment` de `dev` a `staging`, Terraform piensa que los recursos "han cambiado de namespace" y los **destruye y recrea**, así que no pueden coexistir.

La solución estándar son los **workspaces**: cada entorno tiene su propio fichero de estado (en `.terraform/terraform.tfstate.d/<workspace>/terraform.tfstate`), pero comparten el mismo código. `local_cd.sh` y `deploy_week11.sh` se encargan de seleccionar/crear el workspace correcto antes del apply:

```bash
if terraform workspace list | grep -qE "^[* ]+${ENV}$"; then
    terraform workspace select "$ENV"
else
    terraform workspace new "$ENV"
fi
```

Resultado: `gsx-dev` y `gsx-staging` viven simultáneamente en Minikube y se pueden testar/promocionar por separado.

### How do you ensure staging is tested before prod?
1. **Aislamiento físico de estado y namespace**: cada entorno tiene su propio workspace de Terraform (`dev`/`staging`) y vive en su propio namespace de K8s (`gsx-dev`/`gsx-staging`). Un apply en uno no toca el otro.
2. **Promoción por tag inmutable**: la CI publica tags por SHA. Para "promocionar" a staging, aplicamos exactamente el mismo SHA que ha estado corriendo en dev. No reconstruimos: si dev funciona con `:abc1234`, staging usa `:abc1234`.
3. **Misma definición, distinta escala**: staging usa el mismo `main.tf`, solo cambia `replica_count` y mensaje. Si el deploy a dev funciona con 1 réplica, en staging con 2 replicamos el comportamiento bajo carga modesta antes de tocar prod.
4. **Plan antes de apply** (`-detailed-exitcode`): `verify_week11.sh` ejecuta un `terraform plan` con `-detailed-exitcode` que devuelve `0` si no hay cambios, `2` si hay drift. Cualquier diff inesperado se ve antes de aplicar.

## 5. Pipeline de CI/CD (`.github/workflows/ci.yml`)

### Qué pasa en un `push` a `main`
1. **Job `build-and-push`** (paralelo al de validación):
   - Calcula `sha_short`.
   - Login en Docker Hub usando los secrets `DOCKERHUB_USERNAME` y `DOCKERHUB_TOKEN`.
   - Build & push de `pauplanasc/simple-app-gsx:<sha>` y `:latest` desde `week_9/backend`.
   - Build & push de `pauplanasc/nginx-gsx:<sha>` y `:latest` desde `week_9/nginx`.
2. **Job `terraform-validate`**:
   - `terraform fmt -check` (estilo).
   - `terraform init -backend=false` (sin tocar estado remoto).
   - `terraform validate` (sintaxis y referencias).

Si cualquier job falla, la PR/commit queda marcado en rojo y no procedemos al CD local.

### Qué NO hace la CI
**No** ejecuta `terraform apply` contra Minikube — Minikube vive en la VM del estudiante, fuera del runner de GitHub. El apply se lanza a mano con `local_cd.sh`.

## 6. Setup necesario una sola vez

En GitHub → Settings → Secrets and variables → Actions, definir:
- `DOCKERHUB_USERNAME`: tu usuario de Docker Hub.
- `DOCKERHUB_TOKEN`: un Personal Access Token de Docker Hub (Account Settings → Security → New Access Token, permisos Read/Write).

Sin estos secretos, el step `Login to DockerHub` falla y nunca se publica `:latest`, lo que provoca el `ImagePullBackOff` que vimos.
