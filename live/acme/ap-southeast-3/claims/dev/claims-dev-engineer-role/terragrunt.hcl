include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//human-role"
}

dependency "documents_bucket" {
  config_path = "../claims-documents-bucket"

  mock_outputs = {
    bucket_arn = "arn:aws:s3:::acme-claims-documents-dev"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                   = "claims-dev-engineer"
  trusted_principal_arns = ["arn:aws:iam::111111111111:root"]
  max_session_duration   = 3600

  policy_statements = [
    {
      sid       = "ListClaimDocuments"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = [dependency.documents_bucket.outputs.bucket_arn]
    },
    {
      sid    = "ReadWriteClaimDocuments"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
      ]
      resources = ["${dependency.documents_bucket.outputs.bucket_arn}/*"]
    },
  ]
}
