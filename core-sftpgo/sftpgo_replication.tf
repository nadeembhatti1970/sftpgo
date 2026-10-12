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

resource "aws_kms_key" "sftpgo_replica" {
  provider                = aws.replica
  description             = "Encrypt replicated SFTPGo objects in ${var.replica_aws_region}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.sftpgo_replica_key.json

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, { Name = "${local.name}-sftpgo-replica-key" })
}

resource "aws_s3_bucket" "sftpgo_replica" {
  provider = aws.replica
  bucket   = "sftpgo-replica-${var.environment_name}-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
  tags     = merge(var.tags, { Name = "${local.name}-sftpgo-files-replica" })

  # checkov:skip=CKV_AWS_144: This is the terminal cross-region replica bucket.
  # checkov:skip=CKV_AWS_18: Server access logging is intentionally disabled; S3 audit logging is not required.
  # checkov:skip=CKV2_AWS_62: S3 event notifications are intentionally disabled; S3 event auditing is not required.

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "sftpgo_replica" {
  provider                = aws.replica
  bucket                  = aws_s3_bucket.sftpgo_replica.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "sftpgo_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.sftpgo_replica.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sftpgo_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.sftpgo_replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.sftpgo_replica.arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "sftpgo_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.sftpgo_replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "sftpgo_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.sftpgo_replica.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "sftpgo_source_key" {
  # checkov:skip=CKV_AWS_111: KMS key policies require Resource "*" and this document is attached only to the source key.
  # checkov:skip=CKV_AWS_356: KMS key policies require Resource "*" and this document is attached only to the source key.
  # checkov:skip=CKV_AWS_109: KMS key policies require Resource "*" and this document is attached only to the source key.
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
    sid    = "AllowSftpGoAndReplicationUse"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.sftpgo_s3.arn,
        aws_iam_role.sftpgo_replication.arn,
      ]
    }
  }
}

data "aws_iam_policy_document" "sftpgo_replica_key" {
  # checkov:skip=CKV_AWS_111: KMS key policies require Resource "*" and this document is attached only to the replica key.
  # checkov:skip=CKV_AWS_356: KMS key policies require Resource "*" and this document is attached only to the replica key.
  # checkov:skip=CKV_AWS_109: KMS key policies require Resource "*" and this document is attached only to the replica key.
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
    sid    = "AllowReplicationRoleUse"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.sftpgo_replication.arn]
    }
  }
}

data "aws_iam_policy_document" "sftpgo_replication_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sftpgo_replication" {
  name               = "${local.name}-sftpgo-replication"
  assume_role_policy = data.aws_iam_policy_document.sftpgo_replication_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "sftpgo_replication" {
  statement {
    sid       = "ReadSourceBucketConfiguration"
    effect    = "Allow"
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [aws_s3_bucket.sftpgo.arn]
  }

  statement {
    sid    = "ReadSourceObjectVersions"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.sftpgo.arn}/*"]
  }

  statement {
    sid    = "WriteReplicaObjects"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]
    resources = ["${aws_s3_bucket.sftpgo_replica.arn}/*"]
  }

  statement {
    sid       = "DecryptSourceObjects"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.sftpgo_source.arn]
  }

  statement {
    sid       = "EncryptReplicaObjects"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.sftpgo_replica.arn]
  }
}

resource "aws_iam_role_policy" "sftpgo_replication" {
  name   = "${local.name}-sftpgo-replication"
  role   = aws_iam_role.sftpgo_replication.id
  policy = data.aws_iam_policy_document.sftpgo_replication.json
}

resource "aws_s3_bucket_replication_configuration" "sftpgo" {
  bucket = aws_s3_bucket.sftpgo.id
  role   = aws_iam_role.sftpgo_replication.arn

  rule {
    id     = "replicate-all-objects"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.sftpgo_replica.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.sftpgo_replica.arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.sftpgo,
    aws_s3_bucket_versioning.sftpgo_replica,
    aws_iam_role_policy.sftpgo_replication,
  ]
}
