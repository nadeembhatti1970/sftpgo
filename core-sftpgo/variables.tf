variable "aws_region" {
  description = "AWS region for the SFTPGo bucket and EKS cluster"
  type        = string
  default     = "eu-west-2"
}

variable "replica_aws_region" {
  description = "AWS region for the SFTPGo S3 replication destination"
  type        = string
  default     = "eu-west-1"

  validation {
    condition     = var.replica_aws_region != var.aws_region
    error_message = "The SFTPGo replication destination must use a different AWS region."
  }
}

variable "environment_name" {
  description = "Environment name used in resource names and tags"
  type        = string
  default     = "dev"
}

variable "business_division" {
  description = "Business division used in resource names"
  type        = string
  default     = "devops"
}

variable "sftpgo_namespace" {
  description = "Kubernetes namespace used by the SFTPGo Helm release"
  type        = string
  default     = "sftpgo"
}

variable "sftpgo_service_account_name" {
  description = "Kubernetes service account used by the SFTPGo deployment"
  type        = string
  default     = "sftpgo"
}

variable "tags" {
  description = "Tags applied to SFTPGo resources"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}
