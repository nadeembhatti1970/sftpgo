data "aws_iam_policy_document" "sftpgo_plan_trust" {
  statement {
    sid     = "SftpGoBranchAndPullRequestPlans"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values = [
        "${local.repository_subject}:ref:refs/heads/*",
        "${local.repository_subject}:pull_request",
      ]
    }
  }
}

data "aws_iam_policy_document" "sftpgo_apply_trust" {
  statement {
    sid     = "SftpGoMainApply"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:sub"
      values   = ["${local.repository_subject}:ref:refs/heads/${var.apply_branch}"]
    }
  }
}
