terraform {
  backend "s3" {
    bucket         = "DEIN_TFSTATE_BUCKET"
    key            = "syntax-projekt/prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "DEINE_TF_LOCK_TABLE"
    encrypt        = true
  }
}
