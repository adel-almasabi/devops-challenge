include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//sqs-queue"
}

inputs = {
  name                        = "claims-documents-dev"
  visibility_timeout_seconds  = 300
  max_receive_count           = 5
  alarm_age_threshold_seconds = 3600
}
