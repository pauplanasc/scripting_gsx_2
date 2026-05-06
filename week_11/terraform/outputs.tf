output "namespace" {
  description = "Namespace de Kubernetes donde se ha desplegado este entorno"
  value       = kubernetes_namespace.env_namespace.metadata[0].name
}

output "image_tag_deployed" {
  description = "Tag de la imagen Docker aplicada en este apply (commit SHA o latest)"
  value       = var.image_tag
}

output "backend_replicas" {
  description = "Numero de replicas del backend para este entorno"
  value       = var.replica_count
}

output "nginx_node_port" {
  description = "NodePort asignado por K8s al servicio Nginx (acceso externo)"
  value       = kubernetes_service.nginx_svc.spec[0].port[0].node_port
}

output "access_hint" {
  description = "Comando para resolver la URL de acceso desde Minikube"
  value       = "minikube service nginx-service -n ${kubernetes_namespace.env_namespace.metadata[0].name} --url"
}
