# Terraform Backend Setup

This directory creates the AWS infrastructure needed for remote Terraform state management.

## What It Creates

1. **S3 Bucket**: Stores Terraform state files
   - Versioning enabled for state recovery
   - Server-side encryption (AES256)
   - Public access blocked
   - Globally unique name with random suffix

2. **DynamoDB Table**: Provides state locking
   - Prevents concurrent modifications
   - Pay-per-request billing
   - Hash key: LockID

## Usage

### Initial Setup (One-Time)

```bash
cd terraform/backend-setup
terraform init
terraform apply
```

This will output the backend configuration you need.

### Migrate Existing State

After backend is created, add this to your main Terraform code:

```hcl
terraform {
  backend "s3" {
    bucket         = "voting-app-terraform-state-XXXXXXXX"  # From output
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "voting-app-terraform-locks"
  }
}
```

Then migrate:

```bash
cd terraform
terraform init -migrate-state
```

## Benefits

✅ **Team Collaboration**: Multiple team members can work on infrastructure
✅ **State History**: Versioning allows recovery from mistakes
✅ **Locking**: Prevents concurrent modifications that could corrupt state
✅ **Security**: State encrypted at rest
✅ **Backup**: State stored in durable S3 storage

## Cost

- S3: ~$0.50/month (for small state files)
- DynamoDB: ~$0.25/month (pay-per-request, minimal usage)
- **Total: ~$0.75/month**

## Important Notes

- The bucket and table have `prevent_destroy = true` to avoid accidental deletion
- Never delete these resources while active Terraform configurations depend on them
- The state file may contain sensitive data - ensure proper IAM permissions
