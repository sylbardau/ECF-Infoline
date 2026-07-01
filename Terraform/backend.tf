terraform {
  backend "s3" {
    bucket         = "ECF-Infoline" # même nom que dans bootstrap-backend.sh
    key            = "prod/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
