output "bucket_name" {
  value = aws_s3_bucket.demo_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.demo_bucket.arn
}

output "instance_public_ip" {
  value = aws_instance.flask_server.public_ip
}

output "instance_id" {
  value = aws_instance.flask_server.id
}
