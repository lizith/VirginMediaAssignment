variable "project_id" {
  description = "The ID of the GCP project where the resources will be created."
}

variable "region" {
  description = "The region where the resources will be created."
}

variable "master_password" {
  description = "Password for the Kubernetes master user."
  type        = string
  default     = "changeme"
}