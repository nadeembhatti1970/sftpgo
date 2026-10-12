# SFTPGo GitHub Actions OIDC roles

This Terraform root creates dedicated GitHub Actions plan and apply roles for
the SFTPGo repository. It looks up the shared GitHub Actions OIDC provider
created by `core-infra/github-oidc`; it does not create or alter that shared
provider.

The plan role accepts only SFTPGo branch and pull request subjects, has
read-only AWS access, and can lock only the SFTPGo application state. The apply
role accepts only `main`, can manage the SFTPGo Terraform resources, can publish
Helm OCI artifacts to the `sftpgo` ECR repository, and has explicit guardrails
against modifying the shared OIDC provider, core-infra CI roles, or Terraform
state bucket configuration.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.20 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.20 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.sftpgo_ecr_push](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.sftpgo_terraform_apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.sftpgo_apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.sftpgo_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.sftpgo_apply_guardrails](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.sftpgo_apply_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.sftpgo_plan_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.sftpgo_ecr_push](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.sftpgo_plan_readonly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.sftpgo_terraform_apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.sftpgo_apply_guardrails](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sftpgo_apply_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sftpgo_apply_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sftpgo_ecr_push](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sftpgo_plan_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sftpgo_plan_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_apply_branch"></a> [apply\_branch](#input\_apply\_branch) | Only this branch may assume the Terraform apply and chart-publish role | `string` | `"main"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for SFTPGo's GitHub Actions roles | `string` | `"eu-west-2"` | no |
| <a name="input_business_division"></a> [business\_division](#input\_business\_division) | Business division used in role names and tags | `string` | `"devops"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name used in role names and tags | `string` | `"dev"` | no |
| <a name="input_github_repository"></a> [github\_repository](#input\_github\_repository) | SFTPGo GitHub repository allowed to assume these roles | `string` | `"nadeembhatti1970/stfpgo"` | no |
| <a name="input_github_repository_id"></a> [github\_repository\_id](#input\_github\_repository\_id) | Immutable GitHub repository ID used in the OIDC subject | `string` | `"1415458344"` | no |
| <a name="input_github_repository_owner_id"></a> [github\_repository\_owner\_id](#input\_github\_repository\_owner\_id) | Immutable GitHub owner ID used in the OIDC subject | `string` | `"13079239"` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum GitHub Actions role session duration in seconds | `number` | `7200` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to SFTPGo GitHub OIDC resources | `map(string)` | <pre>{<br/>  "Terraform": "true"<br/>}</pre> | no |
| <a name="input_tfstate_bucket_name"></a> [tfstate\_bucket\_name](#input\_tfstate\_bucket\_name) | S3 bucket containing Terraform state | `string` | `"tfstate-dev-eu-west-2-8cbztj"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_sftpgo_github_actions_apply_role_arn"></a> [sftpgo\_github\_actions\_apply\_role\_arn](#output\_sftpgo\_github\_actions\_apply\_role\_arn) | SFTPGo GitHub Actions role for main-branch applies and chart publishing |
| <a name="output_sftpgo_github_actions_plan_role_arn"></a> [sftpgo\_github\_actions\_plan\_role\_arn](#output\_sftpgo\_github\_actions\_plan\_role\_arn) | SFTPGo GitHub Actions role for branch and pull request plans |
<!-- END_TF_DOCS -->

## One-time bootstrap

This root is bootstrapped with the administrative AWS profile because GitHub
Actions credentials do not exist until these roles have been created. Run from
the SFTPGo repository:

```bash
AWS_PROFILE=AdministratorAccess-042170206259 terraform -chdir=core-sftpgo-oidc init
AWS_PROFILE=AdministratorAccess-042170206259 terraform -chdir=core-sftpgo-oidc plan
AWS_PROFILE=AdministratorAccess-042170206259 terraform -chdir=core-sftpgo-oidc apply
```

After bootstrap, the root `SFTPGo` workflow assumes the plan or apply role and
deploys `core-sftpgo`. Role ARNs are exposed as Terraform outputs. Re-run this
root with the administrative profile if GitHub trust, role permissions, or
session settings need to change.
