# SFTPGo platform

This repository contains the SFTPGo Helm chart and its AWS infrastructure.

## GitHub Actions deployment

The `SFTPGo` workflow runs Terraform format, validation, Checkov static and plan scans, the destroy gate, and native Terraform tests on pushes and pull requests. Pushes to non-main branches and pull requests create a read-only Terraform plan. Pushes to `main` and manual runs on `main` apply the reviewed plan and publish the chart to the private Amazon ECR OCI repository in `eu-west-2`.

The chart is a Git submodule at `sftpgo-helm-chart`. Commit chart changes in that repository, then update the submodule pointer in this repository. The workflow checks out submodules recursively.

For publishing, Actions reads `appVersion` from `sftpgo-helm-chart/sftpgo/Chart.yaml` and sets the packaged chart's `version` to `appVersion+git.<full-commit-sha>`. The committed chart file is not changed by the workflow. Helm OCI registries encode the SemVer `+` build separator as `_` in the registry tag.

## One-time setup

1. Ensure the shared GitHub Actions OIDC provider exists by applying `core-infra/github-oidc` if it has not already been deployed.
2. From this repository, apply `core-sftpgo-oidc` using the administrative AWS profile. The plan role trusts SFTPGo branch and pull request tokens; the apply role trusts only `main`.
3. Apply `core-sftpgo` to create the S3 storage resources and immutable ECR repository named `sftpgo`.
4. Enable Actions for this repository and allow GitHub's OIDC token permission. No long-lived AWS credentials are required.

Changes under `core-sftpgo-oidc` run a separate checks-only workflow. Apply OIDC role or trust changes from an administrative session using the documented bootstrap commands; the app deployment role is intentionally unable to change its own permissions.

The Terraform project README has the S3 backend configuration and outputs. The chart README has chart-specific configuration instructions.
