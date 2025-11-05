# S3 Bucket for Terraform State (The DeLorean Vault)
resource "aws_s3_bucket" "flux_capacitor_state" {
  bucket = "${var.project_name}-terraform-state-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "flux-capacitor-terraform-state"
    Purpose     = "Terraform state storage - DO NOT DELETE"
    Owner       = "Marty McFly"
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

# Enable versioning for state file backup (Time Travel Protection)
resource "aws_s3_bucket_versioning" "flux_capacitor_versioning" {
  bucket = aws_s3_bucket.flux_capacitor_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for state file (Plutonium Encryption)
resource "aws_s3_bucket_server_side_encryption_configuration" "flux_capacitor_encryption" {
  bucket = aws_s3_bucket.flux_capacitor_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access (Private Timeline)
resource "aws_s3_bucket_public_access_block" "flux_capacitor_block_public" {
  bucket = aws_s3_bucket.flux_capacitor_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy to manage old versions (Temporal Cleanup)
resource "aws_s3_bucket_lifecycle_configuration" "flux_capacitor_lifecycle" {
  bucket = aws_s3_bucket.flux_capacitor_state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# DynamoDB Table for State Locking (The Time Lock)
resource "aws_dynamodb_table" "time_lock" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "time-lock-terraform-locks"
    Purpose     = "Terraform state locking - DO NOT DELETE"
    Owner       = "Marty McFly"
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}
