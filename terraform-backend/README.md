# Terraform Backend Infrastructure

## Purpose
This folder creates the foundational infrastructure for storing Terraform state remotely.

**Created Resources:**
- **S3 Bucket** (`flux-capacitor-state`) - Stores terraform.tfstate files
- **DynamoDB Table** (`time-lock`) - Provides state locking mechanism

## Why Separate Folder?
The backend infrastructure must exist BEFORE the main project can use it. This folder uses local state to bootstrap the remote backend.

## Security Features
✅ **Lifecycle Protection** - `prevent_destroy = true` blocks accidental deletion
✅ **Encryption** - AES256 server-side encryption for state files
✅ **Versioning** - S3 versioning enabled for state file history
✅ **Point-in-Time Recovery** - DynamoDB backup enabled
✅ **Public Access Blocked** - S3 bucket is completely private

## Usage

### Initial Setup (One Time Only)
```bash
cd terraform-backend/
terraform init
terraform apply
```

**Important:** This state file stays LOCAL. Do not delete this folder.

### After Setup
Copy the backend configuration from outputs and add to main project's `provider.tf`.

## ⚠️ CRITICAL WARNING
**NEVER run `terraform destroy` in this folder unless:**
1. You've already destroyed all infrastructure in the main project
2. You've backed up all state files
3. You're permanently decommissioning the entire project

The `prevent_destroy` lifecycle will block destruction, but can be overridden.

## Cost
~$0.02/month (essentially free)
- S3: ~$0.01/month
- DynamoDB (on-demand): ~$0.01/month

## BTTF Theme
- **Flux Capacitor** = S3 bucket (stores the timeline/state)
- **Time Lock** = DynamoDB table (prevents concurrent modifications)
