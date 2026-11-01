include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//s3-bucket"
}

inputs = {
  name          = "acme-claims-documents-dev"
  versioning    = false
  force_destroy = true

  lifecycle_rules = [
    {
      id              = "expire-test-data"
      prefix          = ""
      expiration_days = 30
    },
  ]
}
