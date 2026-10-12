mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:root"
      user_id    = "AIDATEST"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/sftpgo-test"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/sftpgo-test"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:eu-west-2:123456789012:key/11111111-1111-1111-1111-111111111111"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::sftpgo-test"
    }
  }
}

mock_provider "aws" {
  alias = "replica"

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/sftpgo-test"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:eu-west-1:123456789012:key/22222222-2222-2222-2222-222222222222"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::sftpgo-replica-test"
    }
  }
}

mock_provider "random" {}

override_data {
  target = data.terraform_remote_state.eks

  values = {
    outputs = {
      eks_cluster_name = "sftpgo-test-cluster"
    }
  }
}

override_data {
  target = data.aws_iam_policy_document.sftpgo_bucket_tls
  values = {
    json = jsonencode({ Version = "2012-10-17", Statement = [] })
  }
}

override_data {
  target = data.aws_iam_policy_document.sftpgo_pod_identity_assume
  values = {
    json = jsonencode({ Version = "2012-10-17", Statement = [] })
  }
}

override_data {
  target = data.aws_iam_policy_document.sftpgo_s3_access
  values = {
    json = jsonencode({
      Version   = "2012-10-17"
      Statement = [{ Action = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"] }]
    })
  }
}

override_data {
  target = data.aws_iam_policy_document.sftpgo_replication_assume
  values = {
    json = jsonencode({ Version = "2012-10-17", Statement = [] })
  }
}

override_data {
  target = data.aws_iam_policy_document.sftpgo_replication
  values = {
    json = jsonencode({ Version = "2012-10-17", Statement = [] })
  }
}

override_data {
  target = data.aws_iam_policy_document.sftpgo_source_key
  values = {
    json = jsonencode({ Version = "2012-10-17", Statement = [] })
  }
}

override_data {
  target = data.aws_iam_policy_document.sftpgo_replica_key
  values = {
    json = jsonencode({ Version = "2012-10-17", Statement = [] })
  }
}

run "bucket_encryption_and_replication" {
  command = apply

  assert {
    condition = one([
      for rule in aws_s3_bucket_server_side_encryption_configuration.sftpgo.rule : one([
        for encryption in rule.apply_server_side_encryption_by_default : encryption.sse_algorithm
      ])
    ]) == "aws:kms"
    error_message = "The source bucket must use KMS encryption."
  }

  assert {
    condition = one([
      for rule in aws_s3_bucket_replication_configuration.sftpgo.rule : one([
        for destination in rule.destination : destination.bucket
      ])
    ]) == aws_s3_bucket.sftpgo_replica.arn
    error_message = "The source bucket must replicate to the configured replica bucket."
  }

  assert {
    condition = one([
      for rule in aws_s3_bucket_replication_configuration.sftpgo.rule : one([
        for destination in rule.destination : one([
          for encryption in destination.encryption_configuration : encryption.replica_kms_key_id
        ])
      ])
    ]) == aws_kms_key.sftpgo_replica.arn
    error_message = "Replicated objects must use the replica-region KMS key."
  }

  assert {
    condition     = aws_s3_bucket_versioning.sftpgo_replica.versioning_configuration[0].status == "Enabled"
    error_message = "The replica bucket must have versioning enabled."
  }
}

run "sftpgo_has_scoped_kms_access" {
  command = apply

  assert {
    condition     = strcontains(data.aws_iam_policy_document.sftpgo_s3_access.json, "kms:GenerateDataKey")
    error_message = "The SFTPGo workload policy must allow KMS data-key generation."
  }
}
