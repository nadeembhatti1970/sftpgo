output "sftpgo_github_actions_plan_role_arn" {
  description = "SFTPGo GitHub Actions role for branch and pull request plans"
  value       = aws_iam_role.sftpgo_plan.arn
}

output "sftpgo_github_actions_apply_role_arn" {
  description = "SFTPGo GitHub Actions role for main-branch applies and chart publishing"
  value       = aws_iam_role.sftpgo_apply.arn
}
