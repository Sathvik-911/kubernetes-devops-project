# The staging environment: its own namespace, with limits so it can never
# starve the rest of the cluster.

resource "kubernetes_namespace_v1" "staging" {
  metadata {
    name = var.namespace
    labels = {
      environment  = "staging"
      "managed-by" = "terraform"
    }
  }
}

# Hard caps for the whole namespace
resource "kubernetes_resource_quota_v1" "staging" {
  metadata {
    name      = "staging-quota"
    namespace = kubernetes_namespace_v1.staging.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "1"
      "requests.memory" = "1Gi"
      "limits.cpu"      = "2"
      "limits.memory"   = "2Gi"
      "pods"            = "10"
    }
  }
}

# Defaults for containers that don't declare their own resources
resource "kubernetes_limit_range_v1" "staging" {
  metadata {
    name      = "staging-defaults"
    namespace = kubernetes_namespace_v1.staging.metadata[0].name
  }
  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "200m"
        memory = "128Mi"
      }
      default_request = {
        cpu    = "50m"
        memory = "64Mi"
      }
    }
  }
}