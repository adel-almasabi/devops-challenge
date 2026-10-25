variable "name" {
  description = "Bucket name."
  type        = string
}

variable "versioning" {
  description = "Enable object versioning."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket even if it contains objects."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Expiration rules by prefix."
  type = list(object({
    id              = string
    prefix          = string
    expiration_days = number
  }))
  default = []
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
