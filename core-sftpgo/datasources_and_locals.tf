data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "tfstate-dev-eu-west-2-8cbztj"
    key    = "eks/dev/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  name         = "${var.business_division}-${var.environment_name}"
  cluster_name = data.terraform_remote_state.eks.outputs.eks_cluster_name
  cluster_arn  = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.cluster_name}"
  user_prefix  = "users/"
}
