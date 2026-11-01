variable "name" {
  description = "SNS topic name."
  type        = string
}

variable "email_subscribers" {
  description = "Email addresses receive alarm."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
