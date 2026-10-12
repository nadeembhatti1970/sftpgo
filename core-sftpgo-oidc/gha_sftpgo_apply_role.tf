resource "aws_iam_role" "sftpgo_apply" {
  name                 = local.apply_role_name
  description          = "GitHub Actions main-branch Terraform apply and chart publish role for SFTPGo"
  assume_role_policy   = data.aws_iam_policy_document.sftpgo_apply_trust.json
  max_session_duration = var.max_session_duration

  # checkov:skip=CKV_AWS_393: Trust is pinned to the immutable repository and owner IDs and the exact apply branch; Checkov currently parses only legacy owner/repo subjects.
  tags = merge(local.common_tags, {
    Name      = local.apply_role_name
    Component = "SFTPGo GitHub Actions apply"
  })
}

resource "aws_iam_policy" "sftpgo_terraform_apply" {
  name        = "${local.apply_role_name}-terraform"
  description = "Scoped Terraform permissions for the SFTPGo project"
  policy      = file("${path.module}/sftpgo_terraform_apply_policy.json")

  # checkov:skip=CKV_AWS_355: KMS CreateKey requires Resource *; creation is restricted to requests carrying the Terraform tag and all other permissions are resource-scoped.
  tags = merge(local.common_tags, {
    Name      = "${local.apply_role_name}-terraform"
    Component = "SFTPGo Terraform apply"
  })
}

resource "aws_iam_role_policy_attachment" "sftpgo_terraform_apply" {
  role       = aws_iam_role.sftpgo_apply.name
  policy_arn = aws_iam_policy.sftpgo_terraform_apply.arn
}

data "aws_iam_policy_document" "sftpgo_apply_state" {
  statement {
    sid       = "ListSftpGoStatePrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [local.tfstate_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["sftpgo/dev/terraform.tfstate", "sftpgo/dev/terraform.tfstate.tflock"]
    }
  }

  statement {
    sid    = "ManageSftpGoStateAndLock"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${local.tfstate_bucket_arn}/sftpgo/dev/terraform.tfstate",
      "${local.tfstate_bucket_arn}/sftpgo/dev/terraform.tfstate.tflock",
    ]
  }
}

resource "aws_iam_role_policy" "sftpgo_apply_state" {
  name   = "${local.apply_role_name}-state"
  role   = aws_iam_role.sftpgo_apply.id
  policy = data.aws_iam_policy_document.sftpgo_apply_state.json
}

data "aws_iam_policy_document" "sftpgo_ecr_push" {
  statement {
    sid    = "PushSftpGoHelmChart"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = ["arn:${local.partition}:ecr:${var.aws_region}:${local.account_id}:repository/sftpgo"]
  }

  statement {
    sid       = "AuthenticateToEcr"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sftpgo_ecr_push" {
  name        = "${local.apply_role_name}-ecr-push"
  description = "Push Helm OCI charts to the SFTPGo ECR repository"
  policy      = data.aws_iam_policy_document.sftpgo_ecr_push.json
  tags        = merge(local.common_tags, { Name = "${local.apply_role_name}-ecr-push" })
}

resource "aws_iam_role_policy_attachment" "sftpgo_ecr_push" {
  role       = aws_iam_role.sftpgo_apply.name
  policy_arn = aws_iam_policy.sftpgo_ecr_push.arn
}

data "aws_iam_policy_document" "sftpgo_apply_guardrails" {
  statement {
    sid    = "DenyChangesToBootstrapIdentity"
    effect = "Deny"
    actions = [
      "iam:*",
    ]
    resources = [
      data.aws_iam_openid_connect_provider.github.arn,
      local.protected_role_pattern,
      "arn:${local.partition}:iam::${local.account_id}:policy/${local.name}-gha-*",
    ]
  }

  statement {
    sid           = "PassOnlySftpGoRuntimeRole"
    effect        = "Deny"
    actions       = ["iam:PassRole"]
    not_resources = ["arn:${local.partition}:iam::${local.account_id}:role/${local.name}-sftpgo-s3-role"]
  }

  statement {
    sid    = "DenySftpGoStateBucketChanges"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:PutBucketAcl",
      "s3:PutBucketVersioning",
      "s3:PutLifecycleConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:DeleteObjectVersion",
    ]
    resources = [local.tfstate_bucket_arn, "${local.tfstate_bucket_arn}/*"]
  }

  statement {
    sid       = "DenyAccountLevelChangesAndIamUsers"
    effect    = "Deny"
    actions   = ["organizations:Leave*", "organizations:Delete*", "account:*", "iam:CreateUser", "iam:CreateAccessKey", "iam:CreateLoginProfile"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sftpgo_apply_guardrails" {
  name   = "${local.apply_role_name}-guardrails"
  role   = aws_iam_role.sftpgo_apply.id
  policy = data.aws_iam_policy_document.sftpgo_apply_guardrails.json
}
