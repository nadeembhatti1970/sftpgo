mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_iam_openid_connect_provider" {
    defaults = {
      arn = "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "plan_role_trusts_only_sftpgo_repository_branches_and_pull_requests" {
  command = plan

  assert {
    condition = anytrue([
      for c in data.aws_iam_policy_document.sftpgo_plan_trust.statement[0].condition :
      c.test == "StringLike" && c.variable == "token.actions.githubusercontent.com:sub" && contains(c.values, "repo:nadeembhatti1970@13079239/stfpgo@1415458344:ref:refs/heads/*") && contains(c.values, "repo:nadeembhatti1970@13079239/stfpgo@1415458344:pull_request")
    ])
    error_message = "Plan role must trust only SFTPGo repository branch and pull request subjects"
  }

  assert {
    condition = anytrue([
      for c in data.aws_iam_policy_document.sftpgo_plan_trust.statement[0].condition :
      c.variable == "token.actions.githubusercontent.com:aud" && c.values == tolist(["sts.amazonaws.com"])
    ])
    error_message = "Plan role must pin the sts.amazonaws.com audience"
  }
}

run "apply_role_trusts_only_the_apply_branch" {
  command = plan

  assert {
    condition = anytrue([
      for c in data.aws_iam_policy_document.sftpgo_apply_trust.statement[0].condition :
      c.test == "StringEquals" && c.variable == "token.actions.githubusercontent.com:sub" && c.values == tolist(["repo:nadeembhatti1970@13079239/stfpgo@1415458344:ref:refs/heads/main"])
    ])
    error_message = "Apply role must trust only the SFTPGo main branch"
  }
}

run "apply_role_push_access_is_scoped_to_the_sftpgo_ecr_repository" {
  command = plan

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.sftpgo_ecr_push.statement :
      s.sid == "PushSftpGoHelmChart" && s.resources == toset(["arn:aws:ecr:eu-west-2:111122223333:repository/sftpgo"])
    ])
    error_message = "Chart push permissions must target only the SFTPGo ECR repository"
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.sftpgo_ecr_push.statement :
      s.sid == "AuthenticateToEcr" && contains(s.actions, "ecr:GetAuthorizationToken") && s.resources == toset(["*"])
    ])
    error_message = "ECR authentication token permission must be present"
  }
}

run "apply_role_reads_only_eks_state_and_manages_only_sftpgo_state" {
  command = plan

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.sftpgo_apply_state.statement :
      s.sid == "ReadEksStateForClusterLookup" && s.actions == toset(["s3:GetObject"]) && s.resources == toset([
        "arn:aws:s3:::tfstate-dev-eu-west-2-8cbztj/eks/dev/terraform.tfstate",
      ])
    ])
    error_message = "Apply role may read only the EKS state object needed to resolve the cluster name"
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.sftpgo_apply_state.statement :
      s.sid == "ManageSftpGoStateAndLock" && s.resources == toset([
        "arn:aws:s3:::tfstate-dev-eu-west-2-8cbztj/sftpgo/dev/terraform.tfstate",
        "arn:aws:s3:::tfstate-dev-eu-west-2-8cbztj/sftpgo/dev/terraform.tfstate.tflock",
      ])
    ])
    error_message = "Apply role may mutate only the SFTPGo state and its lock object"
  }
}
