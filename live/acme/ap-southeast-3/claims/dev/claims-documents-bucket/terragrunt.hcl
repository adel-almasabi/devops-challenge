include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//s3-bucket"
}

# Customer documents (KTP, hospital receipts, medical documents). This is personal data.
# Dev must only ever hold fake test documents.
inputs = {
  name = "acme-claims-documents-dev"

  # Keep old versions for a while so a wrong delete or overwrite can be undone.
  versioning = true

  # Dev test files are cleaned up automatically.
  lifecycle_rules = [
    { id = "expire-dev-test-files", prefix = "", expiration_days = 30 },
  ]

  tags = {
    DataClassification = "personal-data"
  }
}
