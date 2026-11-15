# Bring existing namespaces under Terraform management without recreating them.
import {
  to = kubernetes_namespace_v1.kubernetes_learning
  id = "kubernetes-learning"
}

import {
  to = kubernetes_namespace_v1.jenkins
  id = "jenkins"
}

import {
  to = kubernetes_namespace_v1.monitoring
  id = "monitoring"
}