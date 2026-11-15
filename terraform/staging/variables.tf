variable "namespace" {
  description = "Name of the staging namespace"
  type        = string
  default     = "visit-counter-staging"
}

variable "image_tag" {
  description = "visit-counter image tag to deploy in staging"
  type        = string
  default     = "1.1.11"
}