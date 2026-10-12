resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "sftpgo" {
  bucket = "sftpgo-${var.environment_name}-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
  tags   = merge(var.tags, { Name = "${local.name}-sftpgo-files" })

  # checkov:skip=CKV_AWS_144: Cross-region replication is not required for this workload; avoid a second bucket and regional storage costs.
  # checkov:skip=CKV_AWS_145: Default SSE-KMS encryption is configured by the separate aws_s3_bucket_server_side_encryption_configuration.sftpgo resource below.
  # checkov:skip=CKV_AWS_18: Server access logging is intentionally disabled; S3 audit logging is not required.
  # checkov:skip=CKV2_AWS_62: S3 event notifications are intentionally disabled; S3 event auditing is not required.

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "sftpgo" {
  bucket                  = aws_s3_bucket.sftpgo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "sftpgo" {
  bucket = aws_s3_bucket.sftpgo.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sftpgo" {
  bucket = aws_s3_bucket.sftpgo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.sftpgo_source.arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "sftpgo" {
  bucket = aws_s3_bucket.sftpgo.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_metric" "sftpgo_user_requests" {
  bucket = aws_s3_bucket.sftpgo.id
  name   = "SftpGoUserRequests"

  filter {
    prefix = local.user_prefix
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "sftpgo" {
  bucket = aws_s3_bucket.sftpgo.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "sftpgo_require_tls" {
  bucket = aws_s3_bucket.sftpgo.id
  policy = data.aws_iam_policy_document.sftpgo_bucket_tls.json

  depends_on = [aws_s3_bucket_public_access_block.sftpgo]
}

data "aws_iam_policy_document" "sftpgo_bucket_tls" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.sftpgo.arn,
      "${aws_s3_bucket.sftpgo.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    condition {
      test     = "Bool"
      variable = "aws:PrincipalIsAWSService"
      values   = ["false"]
    }
  }
}
