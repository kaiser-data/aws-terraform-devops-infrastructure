# Infrastructure Rebuild Log

**Date**: November 5, 2025
**Reason**: Test infrastructure reproducibility and validate all code is in Terraform

## Pre-Destroy State

### Resources to be Destroyed:
- VPC: vpc-0a8dbdb97cf5e1871
- Frontend Instance: i-0a161c78f3a4d2218 (13.124.72.188)
- Backend Instance: i-052e3bbe9fff0ce48 (10.0.2.139)
- Database Instance: i-0b8b1f7a49860c06c (10.0.2.61)
- NAT Gateway: nat-0aab226d09d1145b9
- Elastic IP: eipalloc-09f5d90d6431357f7
- Security Groups: 3 groups
- Subnets: 2 subnets (public + private)
- Route Tables: 2 tables
- Internet Gateway: igw-0a4594447d5b0c601

### Applications Running:
- Vote app (port 80)
- Result app (port 5001)
- Worker app
- Redis
- PostgreSQL
- Prometheus (port 9090)
- Grafana (port 3000)
- Node Exporter (port 9100)

### S3 Backend:
- Bucket: voting-app-terraform-state-yewzx2pp
- DynamoDB Table: voting-app-terraform-locks
- **Note**: Backend infrastructure will be preserved

## Rebuild Steps:

1. ✅ Backup current state
2. ✅ Destroy main infrastructure (keep S3 backend)
   - **Results**: 16 resources destroyed successfully
   - **Preserved**: S3 backend (voting-app-terraform-state-yewzx2pp) and DynamoDB locks
   - **Time**: ~3 minutes

3. ✅ Recreate infrastructure from code
   - **Results**: 16 resources created successfully
   - **Time**: ~5 minutes
   - **New Resources**: See "New Infrastructure" section below
4. ⏳ Redeploy applications
5. Redeploy monitoring
6. Validate everything works

## Destruction Complete

**Destroyed Resources** (16 total):
- 3 EC2 Instances (frontend, backend, database)
- 1 VPC (vpc-0a8dbdb97cf5e1871)
- 2 Subnets (public + private)
- 1 Internet Gateway
- 1 NAT Gateway
- 1 Elastic IP (eipalloc-09f5d90d6431357f7)
- 3 Security Groups
- 2 Route Tables + 2 associations

**Preserved Resources**:
- ✅ S3: voting-app-terraform-state-yewzx2pp
- ✅ DynamoDB: voting-app-terraform-locks

## Expected Outcome:
- New EC2 instances with different IPs
- All applications working
- All monitoring working
- Validates infrastructure is 100% code-defined

---

## New Infrastructure (Created)

### Network Resources
- **VPC**: vpc-017f363c19b915ccd (10.0.0.0/16) - "time-circuit-vpc"
- **Public Subnet**: subnet-0adc1d98fa130b223 (10.0.1.0/24) - "townsquare-subnet-public"
- **Private Subnet**: subnet-0322b4a73afd1b05 (10.0.2.0/24) - "lab-subnet-private"
- **NAT Gateway Elastic IP**: 43.202.116.51 (eipalloc-0a155a5393c6134aa)

### EC2 Instances
**Frontend** (clocktower-voting-frontend):
- Instance ID: (new instance created)
- Public IP: **3.36.116.222** ⬅️ NEW (was 13.124.72.188)
- Private IP: 10.0.1.22
- Security Group: sg-0f45f2f89aeb7462e (bttf-frontend-sg)
- **Ports**: 22 (SSH), 80 (vote), 5001 (result), 9090 (Prometheus), 3000 (Grafana), 9100 (node-exporter)

**Backend** (doc-lab-processor):
- Instance ID: (new instance created)
- Public IP: None (private subnet + NAT)
- Private IP: **10.0.2.75** ⬅️ NEW (was 10.0.2.139)
- Security Group: sg-0318e4600d384b2fb (bttf-backend-sg)
- **Ports**: 22 (SSH from frontend), 6379 (Redis)

**Database** (timeline-archive-db):
- Instance ID: (new instance created)
- Public IP: None (private subnet + NAT)
- Private IP: **10.0.2.115** ⬅️ NEW (was 10.0.2.61)
- Security Group: sg-0b43d76b324bc6b45 (bttf-database-sg)
- **Ports**: 22 (SSH from frontend), 5432 (PostgreSQL)

### Resource Tags
- **Owner**: Marty McFly
- **Theme**: Back to the Future naming convention
- All resources properly tagged for identification

### Deployment Steps Completed
1. ✅ Update SSH configuration with new frontend IP
2. ✅ Terraform auto-generated Ansible inventory files (hosts.yml and group_vars/all.yml)
3. ✅ Test Ansible connectivity (all instances responding)
4. ✅ Install Docker on all instances (Docker 28.5.2)
5. 🔍 **LEARNING EXPERIENCE**: Discovered Ansible `community.docker` module issues
   - **Time spent**: ~3 hours debugging Python Docker SDK compatibility
   - **Root cause**: Multiple Python dependency conflicts (urllib3, Docker SDK versions)
   - **Solution**: Use Docker CLI commands instead of Python SDK
   - **Documentation**: See `docs/DOCKER_SDK_DEBUGGING_CASE_STUDY.md` for complete analysis
6. ⏳ Redeploy Docker applications using CLI approach
7. ⏳ Redeploy monitoring stack
8. ⏳ Validate all services are working

### Key Improvements Made
- ✅ Added `meta: reset_connection` to Docker installation for proper group membership
- ✅ Pinned Docker SDK to compatible versions (docker==6.1.3, urllib3<2.0)
- ✅ Created CLI-based deployment playbooks for reliability
- ✅ Enhanced Terraform to auto-generate complete Ansible variables
