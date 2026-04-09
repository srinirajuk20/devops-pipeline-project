output "bucket_name" {
  value = var.create_bucket ? aws_s3_bucket.demo_bucket[0].bucket : null
}

output "bucket_arn" {
  value = var.create_bucket ? aws_s3_bucket.demo_bucket[0].arn : null
}
