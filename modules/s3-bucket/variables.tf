variable "name" {
  description = "Bucket name."
  type        = string
}

variable "versioning" {
  description = "Enable object versioning. Keeps old versions, so deleted or overwritten objects can be recovered."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket even if it contains objects. Keep false for buckets with real data."
  type        = bool
  default     = false
}

variable "block_public_access" {
  description = "Block all public access to the bucket and its objects."
  type        = bool
  default     = true
}

variable "enforce_tls" {
  description = "Deny any request that does not use HTTPS."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Expiration rules by prefix. An empty prefix applies to every object. With no rule, objects are kept until deleted."
  type = list(object({
    id              = string
    prefix          = string
    expiration_days = number
  }))
  default = []
}

variable "noncurrent_version_expiration_days" {
  description = "When versioning is on, delete old versions after this many days. 0 keeps them forever."
  type        = number
  default     = 30
}

variable "abort_incomplete_multipart_days" {
  description = "Delete the parts of unfinished multipart uploads after this many days. 0 turns the rule off."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
