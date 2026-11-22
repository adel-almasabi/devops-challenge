include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//sqs-queue"
}

inputs = {
  name                        = "claims-documents"
  visibility_timeout_seconds  = 300
  max_receive_count           = 5
  alarm_age_threshold_seconds = 900

  # The alarm now emails this address when it fires and when it recovers.
  # No default on purpose, so a plan or apply without it fails instead of leaving the alarm silent.
  #   export CLAIMS_ALERTS_EMAIL='team-alerts@example.com'
  alarm_email = get_env("CLAIMS_ALERTS_EMAIL")
}
