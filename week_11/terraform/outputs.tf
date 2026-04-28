output "namespace" {
  value = kubernetes_namespace.env_namespace.metadata[0].name
}