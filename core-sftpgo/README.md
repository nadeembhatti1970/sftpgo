# SFTPGo S3 storage

This Terraform project creates a private, KMS-encrypted S3 bucket used for
SFTPGo user files, replicates objects to a second AWS region, and creates a
dedicated EKS Pod Identity role. The role is associated with the
`sftpgo/sftpgo` Kubernetes namespace/service-account pair and can access only
objects below the bucket's `users/` prefix. No static AWS credentials are stored
in Kubernetes or SFTPGo. CloudTrail S3 object data events are not configured.

## Deploy the infrastructure

The EKS project must already be applied and the EKS Pod Identity Agent add-on
must be active. Initialize and apply this project:

```bash
terraform init
terraform plan
terraform apply
terraform output
```

Keep the buckets and KMS keys: their Terraform resources have
`prevent_destroy` enabled. Versioning is enabled in both regions so overwritten
or deleted files can be recovered. Replication uses a customer-managed KMS key
in each region. Existing objects are not backfilled when replication is first
enabled; this bucket is intended to be new and empty when deployed. Version
history, replica storage, KMS requests, and cross-region transfer incur AWS
charges. Incomplete multipart uploads are cleaned up after seven days. S3
request metrics are enabled for the `users/` prefix; CloudWatch charges may
apply for these metrics. CloudTrail object data events, S3 event notifications,
and S3 server access logging are intentionally not configured.

## Connect SFTPGo

The Helm release must run in namespace `sftpgo` and use service account `sftpgo`.
The chart's `values-dev.yaml` sets this service-account name. Install the chart
after applying this project so the EKS Pod Identity association is active.

In SFTPGo WebAdmin, set the storage backend for each user to **S3** and use:

- Bucket: `terraform output -raw bucket_name`
- Region: `terraform output -raw bucket_region`
- Key prefix: `users/<username>/`
- Access key and secret: leave empty; the SFTPGo pod obtains temporary
  credentials through EKS Pod Identity.

The cross-region copy bucket is available as `terraform output -raw
replica_bucket_name` in `replica_bucket_region`. It is for recovery and should
not be configured as the active SFTPGo storage backend.

SFTPGo's S3 backend supports multipart transfers, but S3 does not implement all
local filesystem operations: `chmod`, `chown`, symlinks, and atomic directory
renames are unavailable. The chart's persistent volume remains enabled for the
SFTPGo database and temporary-file requirements. S3 storage and request costs
depend on stored data and upload/download activity. No S3 event audit trail is
created by this project.
