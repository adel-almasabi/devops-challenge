variable "name" {
  description = "Queue name. The dead-letter queue is named <name>-dlq."
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "How long a received message stays invisible to other consumers."
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "How long SQS keeps a message that has not been deleted."
  type        = number
  default     = 345600
}

variable "max_receive_count" {
  description = "Receives before a message is moved to the dead-letter queue."
  type        = number
  default     = 5
}

variable "alarm_age_threshold_seconds" {
  description = "Alarm when the oldest message is older than this."
  type        = number
  default     = 900
}

variable "alarm_actions" {
  description = "ARNs to notify when the alarm changes state."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
