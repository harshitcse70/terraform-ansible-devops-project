output "bucket_name" {
  description = "S3 bucket name for remote state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table" {
  description = "DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}
