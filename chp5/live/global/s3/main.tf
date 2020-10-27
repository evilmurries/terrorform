provider "aws" {
    region = "us-east-2"
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