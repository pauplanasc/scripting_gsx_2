# GreenDevCorp — Infraestructura como Código

Repositorio de las prácticas de **Gestió de Sistemes i Xarxes (GSX)** del curso 3r/2n quatrimestre.

Cubre dos entregables:

- **Práctica 1** (semanas 1-5): un servidor Debian 12 desplegado y operado únicamente con scripts Bash y herramientas nativas de Linux (UFW, systemd, cgroups, PAM, rsync).
- **Práctica 2** (semanas 8-13, **nivel Intermediate**): infraestructura cloud-native moderna con Docker, Docker Compose, Kubernetes, Terraform como IaC, GitHub Actions como CI, NetworkPolicies para segmentación, y diseño de red corporativa con identidad centralizada.

---

## Práctica 2 — Resumen rápido

**Objetivo**: levantar y operar un stack tres-capas (nginx → backend Node.js → Redis) en Kubernetes, con dos entornos (`gsx-dev` y `gsx-staging`) aislados por NetworkPolicies y desplegados desde código (Terraform + GitHub Actions).

### Stack

| Capa | Tecnología | Por qué |
|---|---|---|
| Container runtime | Docker | Estándar; build de imágenes locales y Docker Hub |
| Container orchestration | Kubernetes (Minikube + Calico CNI) | Calico para que las NetworkPolicies funcionen |
| Infrastructure as Code | Terraform 1.x con provider `hashicorp/kubernetes` | Declarativo, idempotente, multi-entorno con workspaces |
| CI | GitHub Actions | Build + push imágenes a Docker Hub + `terraform validate` |
| CD | Manual desde la VM (`bash local_cd.sh <env> <sha>`) | GitHub Actions no alcanza un Minikube local |
| Networking | NetworkPolicies de K8s + Calico | Default-deny + allows mínimos (defense in depth) |

### Estructura del repositorio (Práctica 2)

```
.
├── .github/workflows/ci.yml         # CI: build images + push + tf validate
├── week_8/                          # Containerización: Dockerfiles
├── week_9/                          # Docker Compose (stack tres-capas local)
├── week_10/                         # Manifiestos K8s a mano (educativo)
├── week_11/                         # Terraform IaC con workspaces dev/staging
│   ├── terraform/
│   ├── deploy_week11.sh
│   ├── local_cd.sh                  # CD local: terraform apply al workspace correspondiente
│   └── verify_week11.sh
├── week_12/                         # NetworkPolicies + diseño de red
│   ├── networkpolicies/
│   ├── deploy_week12.sh
│   └── verify_week12.sh
├── week_13/
│   └── integration_test.sh          # Test full: destroy + redeploy + verify end-to-end
└── docs_2/                          # Documentación detallada por semana
    ├── week8_docker.md
    ├── week9_compose.md
    ├── week10_documentation.md
    ├── week11_documentation.md
    ├── week12_documentation.md
    └── week13_documentation.md      # Arquitectura global + runbook + troubleshooting
```

### Quickstart (máquina nueva)

Pre-requisitos: Debian/Ubuntu, Docker, kubectl, minikube, terraform, git.

```bash
# 1. Clonar
git clone https://github.com/pauplanasc/scripting_gsx_2.git
cd scripting_gsx_2

# 2. Minikube con CNI Calico (imprescindible para NetworkPolicies)
minikube start --cni=calico --driver=docker

# 3. Desplegar dev y staging via Terraform
cd week_11
bash deploy_week11.sh dev latest        # workspace dev
bash local_cd.sh staging latest         # workspace staging

# 4. Aplicar NetworkPolicies
cd ../week_12
bash deploy_week12.sh

# 5. Verificar
bash verify_week12.sh dev               # 6/6 PASS esperados
bash verify_week12.sh staging

# 6. Smoke test
MIP=$(minikube ip)
DEV_PORT=$(kubectl get svc nginx-service -n gsx-dev -o jsonpath='{.spec.ports[0].nodePort}')
curl http://$MIP:$DEV_PORT
# → "🛠️ Entorno de DESARROLLO (Inestable)\nEres el visitante numero: 1"
```

Para rehacer la infra desde cero (Challenge B de la semana 13):

```bash
cd week_13
bash integration_test.sh <sha-tag>
```

### Documentación detallada

| Doc | Cubre |
|---|---|
| [`docs_2/week8_docker.md`](docs_2/week8_docker.md) | Containerización: Dockerfiles, multistage, Docker Hub |
| [`docs_2/week9_compose.md`](docs_2/week9_compose.md) | Docker Compose, redes, volúmenes, healthchecks |
| [`docs_2/week10_documentation.md`](docs_2/week10_documentation.md) | Manifiestos K8s, probes, resource limits |
| [`docs_2/week11_documentation.md`](docs_2/week11_documentation.md) | Terraform IaC, workspaces, CI/CD pipeline |
| [`docs_2/week12_documentation.md`](docs_2/week12_documentation.md) | Diseño de red, CIDR, NetworkPolicies, identity |
| [`docs_2/week13_documentation.md`](docs_2/week13_documentation.md) | **Arquitectura global, runbook, troubleshooting** |
| [`docs_2/reflection_pau.md`](docs_2/reflection_pau.md) | Reflexión individual |

### CI/CD

GitHub Actions: https://github.com/pauplanasc/scripting_gsx_2/actions

- **Trigger**: cada `push` a `main`.
- **Jobs**: build & push de las dos imágenes a Docker Hub (con tag `<sha>` + `latest`) y `terraform fmt + init + validate`.
- **No** ejecuta `terraform apply`: el CD es manual contra Minikube local (la CI vive en GitHub).

---

## Práctica 1 — Documentación

La práctica 1 (servidor Debian con scripts Bash) tiene su propia documentación en [`docs/`](docs/). Quickstart:

```bash
curl -sL https://raw.githubusercontent.com/pauplanasc/scripting_gsx_2/main/bootstrap.sh | bash
```

Más detalle:
- [Manual de operaciones](docs/runbook.md)
- [Diseño de arquitectura](docs/architecture.md)
- [Recuperación de desastres](docs/disaster_recovery.md)
- [Reflexión individual P1](docs/reflection.md)
