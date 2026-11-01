include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//s3-bucket"
}

inputs = {
  name          = "acme-claims-documents-prod"
  versioning    = true
  force_destroy = false
}
