# Creamos un Namespace dedicado para el entorno (dev o staging)
resource "kubernetes_namespace" "env_namespace" {
  metadata {
    name = "gsx-${var.environment}"
  }
}

# --- BACKEND (Node.js) ---
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
  data = {
    APP_MESSAGE = var.app_message
    PORT        = "3000"
  }
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
  spec {
    replicas = var.replica_count
    selector { match_labels = { app = "backend" } }
    template {
      metadata { labels = { app = "backend" } }
      spec {
        container {
          name  = "backend"
          image = "pauplanasc/simple-app-gsx:${var.image_tag}"
          port { container_port = 3000 }
          env_from {
            config_map_ref { name = kubernetes_config_map.app_config.metadata[0].name }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend_svc" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
  spec {
    selector = { app = "backend" }
    port {
      port        = 3000
      target_port = 3000
    }
  }
}

# --- FRONTEND (Nginx) ---
resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
  spec {
    replicas = 1
    selector { match_labels = { app = "nginx" } }
    template {
      metadata { labels = { app = "nginx" } }
      spec {
        container {
          name  = "nginx"
          image = "pauplanasc/nginx-gsx:${var.image_tag}"
          port { container_port = 8080 }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_svc" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
  spec {
    type     = "NodePort"
    selector = { app = "nginx" }
    port {
      port        = 80
      target_port = 8080
    }
  }
}