# Reflexión — Práctica 2 GSX

**Autor**: Pau Planas y Jesus Martinez
**Asignatura**: Gestió de Sistemes i Xarxes
**Práctica**: 2 - Organizational IT Infrastructure
**Nivel**: Intermediate (**)

---

## 1. Lo más desafiante de la práctica

Sin duda lo que más nos costó fue darnos cuenta de que los problemas más bloqueantes no eran de programación sino de **configuración invisible**. El primer ejemplo claro fue cuando nuestro despliegue daba `ImagePullBackOff` y no entendíamos por qué: el código era correcto, las imágenes deberían "estar" en Docker Hub, pero los pods se quedaban en limbo. Tras un buen rato de debug terminamos descubriendo dos cosas a la vez. Una, que la CI nunca había llegado a publicar `:latest` porque los secrets `DOCKERHUB_USERNAME` y `DOCKERHUB_TOKEN` no estaban configurados en GitHub. Y dos, que el archivo `.yml` del workflow lo teníamos dentro de `week_11/.github/workflows/`, no en la raíz del repo, así que GitHub Actions ni siquiera lo detectaba. Tener que aprender que GitHub solo busca workflows en `.github/workflows/` desde el root del repositorio fue de esas lecciones que solo se aprenden bien metiendo la pata. Nos dimos cuenta de cuánto importa la convención: una sola línea mal puesta puede hacer que toda tu infraestructura sea silenciosamente inútil.

Otro atasco grande fue cuando intentamos tener `dev` y `staging` desplegados al mismo tiempo. Aplicábamos `dev` y todo bien. Aplicábamos `staging` y Terraform nos destruía `dev` para reconstruir `staging` en su lugar. Pasamos un rato bastante perdidos pensando que era un bug raro, hasta entender que el problema era de arquitectura: ambos entornos compartían un mismo `terraform.tfstate`, así que cambiar `environment` de `dev` a `staging` se traducía en "los recursos antiguos cambiaron de namespace, los recreo desde cero". La solución fueron los **workspaces de Terraform**, que dan un fichero de estado por entorno. La lección que nos llevamos es que cuando el comportamiento del sistema te parece contraintuitivo, normalmente es porque hay un concepto fundamental que aún no hemos internalizado.

## 2. Lo que más nos sorprendió de la infraestructura moderna

Nos sorprendió la cantidad de patrones que se repiten una y otra vez en herramientas distintas. El "default-deny + allows explícitos" lo vimos primero en las NetworkPolicies de Kubernetes, pero es exactamente la misma lógica que el firewall UFW de la primera práctica o las políticas IAM de cualquier cloud. Aprenderlo una vez te sirve para siempre. Lo mismo con la **idempotencia**: en Terraform es la regla del juego, pero el patrón aparece también en `kubectl apply`, en los playbooks de Ansible, en `INSERT … ON CONFLICT` de SQL. Una vez ves el patrón, te das cuenta de que la mitad de la informática profesional consiste en convertir operaciones imperativas peligrosas en operaciones declarativas seguras y repetibles.

También nos chocó lo poderoso que es el truco de usar el **SHA corto del commit como tag de imagen Docker**. Conecta tres cosas en una sola etiqueta: el código fuente exacto, el binario compilado y la versión desplegada. Mirando un pod en producción puedes ir directo al diff de Git que lo introdujo, sin ambigüedad. Es elegante de una forma que no nos esperábamos.

## 3. Qué haríamos diferente si empezáramos de cero

Dos lecciones operativas. La primera: pondríamos el `.gitignore` el primer día. Tuvimos un susto cuando nos dimos cuenta de que casi habíamos commiteado `terraform.tfstate` —un archivo que contiene el estado completo del cluster, con potenciales secretos— a un repo público. La segunda: configuraríamos los secrets de GitHub Actions el mismo momento en que creamos el workflow, no tres días después. Ambas son cosas pequeñas pero te ahorran horas.

Otra cosa que cambiaríamos: empezar escribiendo `verify_*.sh` **antes** que el `deploy_*.sh`. Si tienes claro desde el principio cómo vas a verificar que algo funciona, todo el desarrollo se convierte en un ciclo "diseño → automatizo → compruebo" mucho más rápido y con menos sorpresas al final. Lo aprendimos trabajando un poco al revés.

## 4. Cómo ha cambiado nuestra visión de DevOps y sistemas cloud-native

Antes pensábamos que "DevOps" era sobre todo desplegar a producción de forma robusta. Ahora vemos que es casi lo opuesto: el objetivo de DevOps es **conseguir que desplegar sea aburrido**. Un push, una CI verde, un comando de CD, y a otra cosa. Para llegar a esa aparente simplicidad hay debajo muchísima ingeniería: IaC versionada, imágenes inmutables, networking segmentado, observabilidad, plan antes de apply, rollback siempre disponible. El estilo "todo escrito en código y revisable" se ha vuelto innegociable para nosotros. Cuando alguien nos proponga editar un manifest a mano en producción, vamos a pensar en este semestre y vamos a decir que no.

## 5. Qué queremos aprender más a fondo

Tres cosas. La primera es **GitOps con ArgoCD**: el siguiente paso natural es que el cluster se baje los cambios solo desde el repo en lugar de empujárselos a mano desde la VM, que sigue siendo el punto débil de nuestro setup actual. La segunda es un stack completo de **observabilidad** (Prometheus + Grafana + Loki + Tempo): hemos diseñado infraestructura que sobrevive a fallos pero, tal y como está hoy, no nos enteraríamos si una pieza se cayese hasta que un usuario reclamara. Y la tercera son los **service mesh** (Istio o Linkerd), sobre todo por el mTLS automático entre servicios y la trazabilidad fina sin tocar el código de la aplicación. Las tres nos parecen áreas que cualquier empresa moderna debería tocar y que están a nuestro alcance con la base que nos ha dejado este semestre.
