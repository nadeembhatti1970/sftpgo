resource "aws_ecr_repository" "sftpgo_helm_chart" {
  name                 = "sftpgo"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  # checkov:skip=CKV_AWS_136: The chart repository uses ECR's AES256 encryption; a customer-managed key is not required for these public-source chart packages.
  # checkov:skip=CKV_AWS_163: ECR image scanning does not scan Helm chart OCI artifacts; the published package contains chart templates and metadata, not a container image.

  encryption_configuration {
    encryption_type = "AES256"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, { Name = "${local.name}-sftpgo-helm-chart" })
}
