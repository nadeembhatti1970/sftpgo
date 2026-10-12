data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id
  name       = "${var.business_division}-${var.environment_name}"

  github_oidc_host   = "token.actions.githubusercontent.com"
  repository_parts   = split("/", var.github_repository)
  repository_subject = "repo:${local.repository_parts[0]}@${var.github_repository_owner_id}/${local.repository_parts[1]}@${var.github_repository_id}"

  plan_role_name  = "${local.name}-sftpgo-gha-terraform-plan"
  apply_role_name = "${local.name}-sftpgo-gha-terraform-apply"

  tfstate_bucket_arn     = "arn:${local.partition}:s3:::${var.tfstate_bucket_name}"
  protected_role_pattern = "arn:${local.partition}:iam::${local.account_id}:role/${local.name}-gha-*"

  common_tags = merge(var.tags, {
    Environment = var.environment_name
    Project     = "sftpgo"
    Component   = "GitHub Actions OIDC"
  })
}
