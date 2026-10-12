resource "aws_kms_key" "sftpgo_source" {
  description             = "Encrypt SFTPGo objects in ${var.aws_region}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.sftpgo_source_key.json

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, { Name = "${local.name}-sftpgo-source-key" })
}

data "aws_iam_policy_document" "sftpgo_source_key" {
  # checkov:skip=CKV_AWS_111: KMS key policies require Resource "*" and this document is attached only to this key.
  # checkov:skip=CKV_AWS_356: KMS key policies require Resource "*" and this document is attached only to this key.
  # checkov:skip=CKV_AWS_109: KMS key policies require Resource "*" and this document is attached only to this key.
  statement {
    sid       = "EnableAccountAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowSftpGoUse"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.sftpgo_s3.arn]
    }
  }
}
