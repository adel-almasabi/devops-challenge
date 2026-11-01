variable "name" {
  description = "IAM role name."
  type        = string
}

variable "trusted_principal_arns" {
  description = "IAM principals allowed to assume the role. MFA is required."
  type        = list(string)
}

variable "max_session_duration" {
  description = "Maximum session length in seconds."
  type        = number
  default     = 3600
}

variable "policy_statements" {
  description = "Inline policy statements attached to the role."
  type = list(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
