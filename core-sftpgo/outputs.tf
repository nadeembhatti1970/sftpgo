output "bucket_name" {
  description = "S3 bucket used for SFTPGo user files"
  value       = aws_s3_bucket.sftpgo.bucket
}

output "bucket_arn" {
  description = "ARN of the SFTPGo file bucket"
  value       = aws_s3_bucket.sftpgo.arn
}

output "bucket_region" {
  description = "AWS region containing the SFTPGo file bucket"
  value       = data.aws_region.current.region
}

output "user_key_prefix" {
  description = "Object key prefix allowed to the SFTPGo workload role"
  value       = local.user_prefix
}

output "pod_identity_role_arn" {
  description = "IAM role associated with the SFTPGo service account"
  value       = aws_iam_role.sftpgo_s3.arn
}

output "pod_identity_association_id" {
  description = "EKS Pod Identity association for SFTPGo"
  value       = aws_eks_pod_identity_association.sftpgo.id
}

output "helm_chart_ecr_repository_url" {
  description = "ECR repository URL for the SFTPGo Helm chart OCI artifact"
  value       = aws_ecr_repository.sftpgo_helm_chart.repository_url
}
