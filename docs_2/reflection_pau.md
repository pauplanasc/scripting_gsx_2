# Reflexión individual — Práctica 2 GSX

> **Autor**: Pau Planas
> **Asignatura**: Gestió de Sistemes i Xarxes
> **Práctica**: 2 - Organizational IT Infrastructure
> **Nivel**: Intermediate (**)
> **Longitud objetivo**: 500-1000 palabras
>
> ---
>
> 📝 **NOTA**: este documento es un **esqueleto** con preguntas guía y prompts para que yo (Pau) escriba mi reflexión personal. Cada bloque tiene 2-3 sub-preguntas y, debajo, espacio para que escriba 1-2 párrafos. Cuando termine, **borro las preguntas guía** y dejo solo mi texto final.

---

## 1. Lo más desafiante de la práctica

> **Preguntas guía:**
> - ¿Qué semana / concepto te costó más? ¿Por qué? Da un ejemplo concreto.
> - ¿Hubo algún error que te atascó horas? ¿Cómo lo resolviste finalmente?
> - ¿Qué aprendiste de ese atasco que no habrías aprendido si todo hubiera ido fluido?
>
> **Pistas concretas que puedes usar (cosas reales que pasaron):**
> - El `ImagePullBackOff` que descubrimos venía de no tener configurados los secrets de Docker Hub en GitHub.
> - El workflow `ci.yml` estaba en `week_11/.github/workflows/` y GitHub Actions nunca lo detectó (debe estar en la raíz).
> - Que un mismo `terraform.tfstate` compartido entre dev y staging hacía que aplicar staging destruyera dev → solución con workspaces.
> - El backend del week_9 necesita Redis y nadie lo había metido en los manifiestos K8s (regresión silenciosa) → 500 al curl.
> - Minikube con kindnet acepta NetworkPolicies pero no las aplica → tuvimos que recrear cluster con Calico.

[**TU TEXTO AQUÍ — 1-2 párrafos**]

---

## 2. Lo que más me sorprendió de la infraestructura moderna

> **Preguntas guía:**
> - ¿Qué tecnología o concepto resultó más distinto de lo que imaginabas?
> - ¿Algo te pareció más simple de lo esperado? ¿Algo más complicado?
> - ¿Qué patrón nuevo aprendiste que ahora ves en muchos sitios?
>
> **Pistas:**
> - El "default-deny + allows" es un patrón de seguridad universal (firewalls, IAM, network policies).
> - "Declarativo vs imperativo" es la misma idea en Terraform, K8s, SQL...
> - Idempotencia: poder ejecutar lo mismo N veces y que el resultado sea el mismo. Brutal para operaciones.
> - El SHA del commit como tag de imagen Docker = trazabilidad mágica.

[**TU TEXTO AQUÍ — 1-2 párrafos**]

---

## 3. Qué haría diferente si empezara de cero

> **Preguntas guía:**
> - ¿Algún archivo / decisión que ahora reorganizarías?
> - ¿Algún tooling que probarías en lugar del actual?
> - ¿Más documentación al principio? ¿Más tests? ¿Otra cosa?
>
> **Pistas:**
> - Empezar con `.gitignore` decente desde el día uno (nos salvó muchos ` terraform.tfstate` mal commiteados).
> - Configurar los secrets de GitHub la primera vez que se crea el workflow, no a los 3 días.
> - Habria sido útil escribir `verify_*.sh` ANTES del `deploy_*.sh` (TDD básico).
> - Tener un `Makefile` o `tasks.sh` único en la raíz que orquestara las semanas.

[**TU TEXTO AQUÍ — 1-2 párrafos**]

---

## 4. Cómo ha cambiado mi visión de DevOps y sistemas cloud-native

> **Preguntas guía:**
> - Antes de la práctica, ¿qué creías que era "DevOps"? ¿Qué crees ahora?
> - ¿Qué cosas haces ahora "automáticamente" que antes ni se te ocurrían?
> - ¿Cómo de aplicable ves esto a tu próximo trabajo / proyecto personal?
>
> **Pistas:**
> - Antes "DevOps" sonaba a deploy de producción. Ahora sé que es: IaC + CI/CD + observabilidad + diseño para fallar.
> - "Si no está en Git, no existe": ya no toleras una pieza de configuración a mano.
> - Ahora ves "trabaja en mi máquina" como un olor a falta de containerización.

[**TU TEXTO AQUÍ — 1-2 párrafos**]

---

## 5. Qué quiero aprender más a fondo

> **Preguntas guía:**
> - De todo lo que hemos tocado, ¿qué te ha picado la curiosidad para investigar más?
> - ¿Algún área que has visto pero hemos dejado al 20%?
>
> **Pistas:**
> - Service mesh (Istio, Linkerd): mTLS automático y observabilidad de red.
> - GitOps con ArgoCD / Flux: el cluster pulla cambios del repo en lugar de empujárselos.
> - Observabilidad real: Prometheus + Grafana + Loki + Tempo (el stack completo de Grafana Labs).
> - eBPF: el siguiente nivel de NetworkPolicies / observabilidad sin sidecars (Cilium).
> - Kubernetes Operators: empaquetar lógica de operación como controladores nativos.

[**TU TEXTO AQUÍ — 1-2 párrafos**]

---

## ✍️ Cómo lo escribo limpio

1. Escribo cada bloque en primera persona, en pasado, con ejemplos concretos del repo.
2. Una vez tengo los 5 bloques, **borro todas las preguntas guía y los corchetes** y dejo solo mis párrafos.
3. Reviso que el total esté entre 500 y 1000 palabras (`wc -w docs_2/reflection_pau.md`).
4. Lo commit-eo con `git commit -m "week 13: individual reflection essay"` y push.
