terraform {
  backend "s3" {
    bucket         = "projektdrees-tfstate-4213"
    key            = "syntax-projekt/prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "projektdrees-terraform-locks"
    encrypt        = true
  }
}
