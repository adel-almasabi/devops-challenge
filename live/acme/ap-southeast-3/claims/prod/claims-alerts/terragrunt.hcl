include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/modules//sns-topic"
}

inputs = {
  name              = "claims-alerts-prod"
  email_subscribers = ["tian6889@gmail.com"]
}
