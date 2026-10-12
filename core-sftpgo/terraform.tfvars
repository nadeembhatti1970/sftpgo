aws_region                  = "eu-west-2"
environment_name            = "dev"
business_division           = "devops"
sftpgo_namespace            = "sftpgo"
sftpgo_service_account_name = "sftpgo"

tags = {
  Terraform   = "true"
  Environment = "dev"
  Project     = "sftpgo"
  ManagedBy   = "platform-team"
}
