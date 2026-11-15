# A complete, disposable copy of the app in the staging namespace.

locals {
  namespace = kubernetes_namespace_v1.staging.metadata[0].name
}

# Generated Redis password: nobody chooses, types or sees it.
resource "random_password" "redis" {
  length  = 24
  special = false
}

resource "kubernetes_secret_v1" "redis" {
  metadata {
    name      = "visit-counter-secret"
    namespace = local.namespace
  }
  data = {
    REDIS_PASSWORD = random_password.redis.result
  }
}

resource "kubernetes_config_map_v1" "visit_counter" {
  metadata {
    name      = "visit-counter-config"
    namespace = local.namespace
  }
  data = {
    REDIS_HOST = "redis"
    REDIS_PORT = "6379"
  }
}

resource "kubernetes_deployment_v1" "redis" {
  metadata {
    name      = "redis"
    namespace = local.namespace
    labels    = { app = "redis" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "redis" }
    }
    template {
      metadata {
        labels = { app = "redis" }
      }
      spec {
        container {
          name  = "redis"
          image = "redis:7-alpine"
          args  = ["redis-server", "--requirepass", "$(REDIS_PASSWORD)"]
          env {
            name = "REDIS_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.redis.metadata[0].name
                key  = "REDIS_PASSWORD"
              }
            }
          }
          port {
            container_port = 6379
          }
          resources {
            requests = { cpu = "50m", memory = "64Mi" }
            limits   = { cpu = "200m", memory = "128Mi" }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "redis" {
  metadata {
    name      = "redis"
    namespace = local.namespace
  }
  spec {
    selector = { app = "redis" }
    port {
      port        = 6379
      target_port = 6379
    }
  }
}

resource "helm_release" "visit_counter" {
  name      = "visit-counter"
  namespace = local.namespace
  chart     = "${path.module}/../../charts/visit-counter"
  values    = [file("${path.module}/../../charts/visit-counter/values-dev.yaml")]

  set = [
    { name = "image.tag", value = var.image_tag },
    # Keep staging out of the production dashboard and alerts
    { name = "serviceMonitor.enabled", value = "false" },
  ]

  wait    = true
  timeout = 300

  depends_on = [
    kubernetes_deployment_v1.redis,
    kubernetes_service_v1.redis,
    kubernetes_config_map_v1.visit_counter,
  ]
}