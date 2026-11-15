output "namespace" {
  description = "The staging namespace created by Terraform"
  value       = kubernetes_namespace_v1.staging.metadata[0].name
}