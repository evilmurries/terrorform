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

resource "aws_iam_user" "example" {
    count = length(var.user_names)
    name = var.user_names[count.index]
}

