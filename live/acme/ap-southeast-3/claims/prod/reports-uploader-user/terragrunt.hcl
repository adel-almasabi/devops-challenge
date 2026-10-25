include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//iam-user"
}

dependency "bucket" {
  config_path = "../reports-bucket"
}

inputs = {
  name       = "claims-reports-uploader"
  bucket_arn = dependency.bucket.outputs.bucket_arn
}
