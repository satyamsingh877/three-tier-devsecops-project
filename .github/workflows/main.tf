# main.tf
provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "three_tier_devsecops_project_bucket" {
  bucket = "three-tier-devsecops-project-bucket-s3"

  tags = {
    Name = "three-tier-devsecops-project-bucket-s3"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.three_tier_devsecops_project_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "lock_files" {
  name         = "lock-files"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "lock-files"
  }
}


