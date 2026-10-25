variable "name" {
  description = "IAM user name."
  type        = string
}

variable "bucket_arn" {
  description = "Bucket the user can access."
  type        = string
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
