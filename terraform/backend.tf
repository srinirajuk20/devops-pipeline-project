terraform {
  backend "s3" {
    bucket         = "rajugsk20-terraform-state-2026"
    key            = "devops-project/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks"
  }
}
