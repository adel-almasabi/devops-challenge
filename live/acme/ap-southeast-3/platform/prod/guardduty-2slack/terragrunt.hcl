include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//guardduty-2slack"
}

inputs = {
  name              = "guardduty-2slack"
  slack_webhook_url = "https://hooks.slack.example.invalid/services/T0ACME/B0ACME/not-a-real-webhook"
  min_severity      = 4
}
