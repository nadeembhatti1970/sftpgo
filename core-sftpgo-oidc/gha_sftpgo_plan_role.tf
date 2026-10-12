resource "aws_iam_role" "sftpgo_plan" {
  name                 = local.plan_role_name
  description          = "GitHub Actions branch and pull request plans for the SFTPGo repository"
  assume_role_policy   = data.aws_iam_policy_document.sftpgo_plan_trust.json
  max_session_duration = var.max_session_duration

  # checkov:skip=CKV_AWS_393: Trust is pinned to immutable repository and owner IDs plus branch or pull_request; Checkov currently parses only legacy owner/repo subjects.
  tags = merge(local.common_tags, {
    Name      = local.plan_role_name
    Component = "SFTPGo GitHub Actions plan"
  })
}

resource "aws_iam_role_policy_attachment" "sftpgo_plan_readonly" {
  role       = aws_iam_role.sftpgo_plan.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "sftpgo_plan_state" {
  statement {
    sid       = "ListRequiredStatePrefixes"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.tfstate_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "sftpgo/dev/terraform.tfstate",
        "sftpgo/dev/terraform.tfstate.tflock",
        "eks/dev/terraform.tfstate",
      ]
    }
  }

  statement {
    sid     = "ReadSftpGoAndEksState"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${local.tfstate_bucket_arn}/sftpgo/dev/terraform.tfstate",
      "${local.tfstate_bucket_arn}/eks/dev/terraform.tfstate",
    ]
  }

  statement {
    sid       = "ManageSftpGoStateLock"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.tfstate_bucket_arn}/sftpgo/dev/terraform.tfstate.tflock"]
  }
}

resource "aws_iam_role_policy" "sftpgo_plan_state" {
  name   = "${local.plan_role_name}-state"
  role   = aws_iam_role.sftpgo_plan.id
  policy = data.aws_iam_policy_document.sftpgo_plan_state.json
}
