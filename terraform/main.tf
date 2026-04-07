resource "aws_s3_bucket" "demo_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "DevOps Terraform Demo Bucket"
    Environment = "Demo"
    Project     = "devops-pipeline-project"
  }
}
