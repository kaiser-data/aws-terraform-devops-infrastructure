# AWS Resource Cleanup Report

**Date**: November 5, 2025

## Terraform Will Destroy (16 resources)

These are all managed and will be recreated:

✅ **3 EC2 Instances**
- Frontend: i-0a161c78f3a4d2218
- Backend: i-052e3bbe9fff0ce48
- Database: i-0b8b1f7a49860c06c

✅ **Network Resources**
- VPC: vpc-0a8dbdb97cf5e1871
- 2 Subnets (public + private)
- Internet Gateway
- NAT Gateway (will recreate with new Elastic IP)
- 2 Route Tables + associations
- 3 Security Groups

✅ **Elastic IP** (for NAT Gateway)
- eipalloc-09f5d90d6431357f7

---

## Resources That Will be PRESERVED

### Intentional (Keep These!)

✅ **S3 Buckets**
- `voting-app-terraform-state-yewzx2pp` - **NEW** Terraform backend (created today)
  - **Status**: Keep - contains Terraform state
  - **Cost**: ~$0.50/month

❓ `bttf-terraform-state-686699774218` - **OLD** Terraform state bucket (from Nov 4)
  - **Status**: Can be deleted (replaced by new backend)
  - **Action**: Delete after confirming new backend works

✅ **DynamoDB Tables**
- `voting-app-terraform-locks` - **NEW** State locking table
  - **Status**: Keep - provides state locking
  - **Cost**: ~$0.25/month

---

## Orphaned Resources (CLEANUP RECOMMENDED)

### 1. Unattached Elastic IPs (COSTING MONEY!)

⚠️ **3 Elastic IPs not in use** - $0.005/hour each = $10.80/month total!

```
3.214.135.21       eipalloc-05699a5215e9669cc
34.197.233.144     eipalloc-0053383d44666f18f
34.225.183.144     eipalloc-0a8a348543db46eb5
```

**Cleanup Command**:
```bash
aws ec2 release-address --allocation-id eipalloc-05699a5215e9669cc
aws ec2 release-address --allocation-id eipalloc-0053383d44666f18f
aws ec2 release-address --allocation-id eipalloc-0a8a348543db46eb5
```

### 2. Available EBS Volumes (Orphaned)

⚠️ **18 available volumes** - ~180 GB total = ~$18/month

These are from terminated EC2 instances but weren't automatically deleted.

**Volumes**: vol-007cf9c7a9abfaf80, vol-0f5971a9e0e2f675d, vol-0c739236cd3fe1fd3, vol-06c8d5c7a2e3fd98a, vol-0952fb52aed368c60, vol-0132cf64ab640a9ff, vol-04508133a8aba7a1c, vol-062edb21105ea6514, vol-0f95a58b3d40e4f7e, vol-082b2483d2f5acc11, vol-0471d470b5168a9bf, vol-0b0e28048dafd3913, vol-0912fb3bd5249ff0d, vol-0b044d43f94d3ffa0, vol-0019001d982f9de73, vol-049cc364306dfaca4, vol-0cd29d97cc0c8a521

**Caution**: Verify these aren't needed by other projects!

**Cleanup Command (CAREFUL!)**:
```bash
# List volumes first to confirm
aws ec2 describe-volumes --volume-ids vol-007cf9c7a9abfaf80 --query 'Volumes[*].[VolumeId,State,CreateTime,Tags]'

# If confirmed orphaned:
aws ec2 delete-volume --volume-id vol-007cf9c7a9abfaf80
# Repeat for each volume
```

---

## Summary

### Will Be Destroyed & Recreated
- 16 Terraform-managed resources ✅

### Keep (New Backend)
- S3: voting-app-terraform-state-yewzx2pp ✅
- DynamoDB: voting-app-terraform-locks ✅

### Cleanup Recommended
- 3 Elastic IPs (save $10.80/month) ⚠️
- 1 Old S3 bucket (save $0.50/month) ⚠️
- 18 EBS volumes (save ~$18/month) ⚠️

### Potential Monthly Savings
- **Total**: ~$29/month if all orphaned resources cleaned up

---

## Next Steps

1. ✅ Destroy Terraform-managed resources
2. ✅ Recreate infrastructure
3. ⚠️ (Optional) Clean up orphaned Elastic IPs
4. ⚠️ (Optional) Delete old S3 bucket after confirming new backend works
5. ⚠️ (Optional) Clean up orphaned EBS volumes (VERIFY FIRST!)
