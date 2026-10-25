variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name prefix for AWS resources"
  type        = string
  default     = "projektdrees"
}

variable "ssh_public_key" {
  description = "Public key used for the EC2 key pair"
  type        = string
  default     = null
}

variable "ad_domain" {
  description = "Active Directory domain name"
  type        = string
  default     = "projektdrees.local"
}

variable "safe_mode_password" {
  description = "Safe mode password for AD forest"
  type        = string
  sensitive   = true
}

variable "domain_admin_password" {
  description = "Password for the domain admin user used during domain join"
  type        = string
  sensitive   = true
}

variable "key_name_suffix" {
  description = "Unique suffix for the EC2 key pair name to avoid duplicates on reruns"
  type        = string
  default     = "default"
}
