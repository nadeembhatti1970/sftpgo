terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20"
    }
  }

  backend "s3" {
    bucket       = "tfstate-dev-eu-west-2-8cbztj"
    key          = "sftpgo-oidc/dev/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
