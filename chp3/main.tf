# config
provider "aws" {
    region = "us-east-2"
}

terraform {
    backend "s3" {
        bucket = "terrorform"
        key = "global/s3/terraform.state"
        region = "us-east-2"

        dynamodb_table = "terrorform-locks"
        encrypt = true
    }
} 

# buckets
resource "aws_s3_bucket" "terrorform_state" {
    bucket = "terrorform"
    acl = "private"

    lifecycle {
        prevent_destroy = true
    }
    versioning {
        enabled = true
    }
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}

# locking db
resource "aws_dynamodb_table" "terraform_locks" {
    name = "terrorform-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    
    attribute {
        name = "LockID"
        type = "S"
    }
}

# outputs
output "s3_bucket_arn" {
    value = aws_s3_bucket.terrorform_state.arn
    description = "The ARN of the S3 state bucket"
}

output "dynamodb_table_name" {
    value = aws_dynamodb_table.terraform_locks.name
    description = "The name of the DynamoDB table"
}