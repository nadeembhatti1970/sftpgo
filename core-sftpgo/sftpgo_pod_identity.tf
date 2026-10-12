data "aws_iam_policy_document" "sftpgo_pod_identity_assume" {
  statement {
    sid     = "AllowSftpGoServiceAccount"
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks-cluster-arn"
      values   = [local.cluster_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = [var.sftpgo_namespace]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [var.sftpgo_service_account_name]
    }
  }
}

resource "aws_iam_role" "sftpgo_s3" {
  name               = "${local.name}-sftpgo-s3-role"
  assume_role_policy = data.aws_iam_policy_document.sftpgo_pod_identity_assume.json
  description        = "SFTPGo EKS workload access to its S3 file bucket"
  tags               = merge(var.tags, { Name = "${local.name}-sftpgo-s3-role" })
}

data "aws_iam_policy_document" "sftpgo_s3_access" {
  statement {
    sid    = "ListSftpGoUserObjects"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [aws_s3_bucket.sftpgo.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [local.user_prefix, "${local.user_prefix}*"]
    }
  }

  statement {
    sid    = "ManageSftpGoUserObjects"
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]

    resources = ["${aws_s3_bucket.sftpgo.arn}/${local.user_prefix}*"]
  }
}

resource "aws_iam_policy" "sftpgo_s3_access" {
  name        = "${local.name}-sftpgo-s3-access"
  description = "Allow SFTPGo to manage objects under the users/ prefix in its bucket"
  policy      = data.aws_iam_policy_document.sftpgo_s3_access.json
  tags        = merge(var.tags, { Name = "${local.name}-sftpgo-s3-access" })
}

resource "aws_iam_role_policy_attachment" "sftpgo_s3_access" {
  role       = aws_iam_role.sftpgo_s3.name
  policy_arn = aws_iam_policy.sftpgo_s3_access.arn
}

resource "aws_eks_pod_identity_association" "sftpgo" {
  cluster_name    = local.cluster_name
  namespace       = var.sftpgo_namespace
  service_account = var.sftpgo_service_account_name
  role_arn        = aws_iam_role.sftpgo_s3.arn
}
