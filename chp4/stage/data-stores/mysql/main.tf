provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "terrorform"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terrorform-locks"
    encrypt        = true
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terrorform"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = "terrorform_db"
  username          = "admin"
  password          = var.db_password
}