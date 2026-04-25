resource "aws_s3_bucket" "demo_bucket" {
  count  = var.create_bucket ? 1 : 0
  bucket = var.bucket_name

  tags = {
    Name        = "DevOps Terraform Demo Bucket"
    Environment = var.environment
    Project     = "devops-pipeline-project"
  }
}
