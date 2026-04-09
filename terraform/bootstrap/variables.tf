variable "bucket_prefix" {
  description = "Prefix for S3 bucket"
  type        = string
  default     = "terraform-states"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for locking"
  type        = string
  default     = "terraform-lock"
}
