# Long-lived namespaces, adopted from existing infrastructure (see imports.tf).
# prevent_destroy makes Terraform refuse any plan that would delete them,
# because deleting a namespace deletes everything inside it.

resource "kubernetes_namespace_v1" "kubernetes_learning" {
  metadata {
    name = "kubernetes-learning"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_namespace_v1" "jenkins" {
  metadata {
    name = "jenkins"
    labels = {
      name = "jenkins"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}