variable "aws_region" {
  description = "AWS region for SFTPGo's GitHub Actions roles"
  type        = string
  default     = "eu-west-2"
}

variable "environment_name" {
  description = "Environment name used in role names and tags"
  type        = string
  default     = "dev"
}

variable "business_division" {
  description = "Business division used in role names and tags"
  type        = string
  default     = "devops"
}

variable "github_repository" {
  description = "SFTPGo GitHub repository allowed to assume these roles"
  type        = string
  default     = "nadeembhatti1970/stfpgo"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in the form <owner>/<repo>."
  }
}

variable "github_repository_owner_id" {
  description = "Immutable GitHub owner ID used in the OIDC subject"
  type        = string
  default     = "13079239"
}

variable "github_repository_id" {
  description = "Immutable GitHub repository ID used in the OIDC subject"
  type        = string
  default     = "1415458344"
}

variable "apply_branch" {
  description = "Only this branch may assume the Terraform apply and chart-publish role"
  type        = string
  default     = "main"
}

variable "tfstate_bucket_name" {
  description = "S3 bucket containing Terraform state"
  type        = string
  default     = "tfstate-dev-eu-west-2-8cbztj"
}

variable "max_session_duration" {
  description = "Maximum GitHub Actions role session duration in seconds"
  type        = number
  default     = 7200

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "tags" {
  description = "Tags applied to SFTPGo GitHub OIDC resources"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}
