include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//irsa-role"
}

dependency "eks" {
  config_path = "../../../platform/prod/eks"

  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::111111111111:oidc-provider/oidc.eks.ap-southeast-3.amazonaws.com/id/MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "queue" {
  config_path = "../claims-documents-queue"
}

dependency "documents_bucket" {
  config_path = "../claims-documents-bucket"

  mock_outputs = {
    bucket_arn = "arn:aws:s3:::acme-claims-documents-prod"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name              = "claims-worker-prod"
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  namespace         = "claims"
  service_account   = "claims-worker"

  policy_statements = [
    {
      sid       = "Queue"
      effect    = "Allow"
      actions   = ["sqs:*"]
      resources = ["*"]
    },
    {
      sid       = "ReadWriteClaimDocuments"
      effect    = "Allow"
      actions   = ["s3:*"]
      resources = ["${dependency.documents_bucket.outputs.bucket_arn}/*"]
    },
  ]
}
