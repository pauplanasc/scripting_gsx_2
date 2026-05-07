# Namespace dedicado por entorno (gsx-dev, gsx-staging) para aislar
# completamente los recursos de cada entorno y demostrar segmentacion.
# La label "environment" la usa la semana 12 para namespaceSelector y para
# que verify_week11 no detecte drift al pasarle deploy_week12 con kubectl label.
resource "kubernetes_namespace" "env_namespace" {
  metadata {
    name = "gsx-${var.environment}"
    labels = {
      environment = var.environment
    }
  }
}

# ConfigMap centralizado: 12-Factor App. La configuracion no vive en la imagen,
# se inyecta en runtime via variables de entorno desde aqui.
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
  data = {
    APP_MESSAGE = var.app_message
    PORT        = "3000"
    REDIS_HOST  = "redis"
  }
}

# --- REDIS (capa de datos para el backend) ---
# El backend de week_9 usa client.incr('visits') contra Redis. Sin este servicio
# el contenedor backend devuelve 500. Lo anyadimos al IaC para que el stack
# completo se pueda recrear con un unico terraform apply.
resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
  spec {
    replicas = 1
    selector { match_labels = { app = "redis" } }
    template {
      metadata { labels = { app = "redis" } }
      spec {
        container {
          name  = "redis"
          image = "redis:7-alpine"
          port { container_port = 6379 }

          resources {
            requests = { memory = "32Mi", cpu = "50m" }
            limits   = { memory = "128Mi", cpu = "200m" }
          }

          liveness_probe {
            tcp_socket { port = 6379 }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          readiness_probe {
            exec { command = ["redis-cli", "ping"] }
            initial_delay_seconds = 2
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis_svc" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.env_namespace.metadata[0].name
  }
  spec {
    selector = { app = "redis" }
    port {
      port        = 6379
      target_port = 6379
    }
  }
}

# --- BACKEND (Node.js) ---
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

          resources {
            requests = { memory = "64Mi", cpu = "100m" }
            limits   = { memory = "128Mi", cpu = "250m" }
          }

          # Liveness por TCP: si el proceso muere, K8s lo reinicia.
          # No usamos HTTP aqui porque "/" devuelve 500 cuando Redis cae,
          # y matar el backend no soluciona un fallo de Redis.
          liveness_probe {
            tcp_socket { port = 3000 }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          # Readiness por HTTP: solo enrutamos trafico cuando "/" responde 200.
          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
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

# --- FRONTEND (Nginx, reverse proxy) ---
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

          resources {
            requests = { memory = "32Mi", cpu = "50m" }
            limits   = { memory = "64Mi", cpu = "100m" }
          }

          liveness_probe {
            tcp_socket { port = 8080 }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
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
