variable "name" {
  description = "Name for the Lambda function and related resources."
  type        = string
  default     = "guardduty-2slack"
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL."
  type        = string
}

variable "min_severity" {
  description = "Only findings with at least this severity are sent to Slack."
  type        = number
  default     = 4
}
