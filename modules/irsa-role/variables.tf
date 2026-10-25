variable "name" {
  description = "IAM role name."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster's IAM OIDC provider."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the service account allowed to assume the role."
  type        = string
}

variable "service_account" {
  description = "Name of the Kubernetes service account allowed to assume the role."
  type        = string
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
