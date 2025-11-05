# 🚀 Quick Start Guide - Voting App Deployment

Complete step-by-step guide to deploy your voting application from scratch.

## ✅ Prerequisites Checklist

Before starting, ensure you have:

- [ ] AWS Account with admin access
- [ ] AWS CLI configured (`aws configure`)
- [ ] Terraform >= 1.6.0 (`terraform --version`)
- [ ] Ansible installed (`ansible --version`)
- [ ] SSH key pair created in AWS ap-northeast-2 region
- [ ] Docker Hub account with vote, result, worker images published
- [ ] Your public IP address (get it: `curl ifconfig.me`)

## 📋 Step-by-Step Deployment

### PHASE 1: Deploy Infrastructure (10-15 minutes)

#### Step 1: Navigate to Terraform Directory

```bash
cd terraform/
```

#### Step 2: Create Configuration File

```bash
cat > terraform.tfvars << EOF
aws_region = "ap-northeast-2"
key_pair_name = "martin-ap-northeast-2-key"
my_ip = "$(curl -s ifconfig.me)/32"
EOF
```

**Important**: Replace `martin-ap-northeast-2-key` with your actual AWS key pair name!

#### Step 3: Initialize Terraform

```bash
terraform init
```

Expected: "Terraform has been successfully initialized!"

#### Step 4: Review Infrastructure Plan

```bash
terraform plan
```

This shows what will be created:
- 1 VPC
- 2 Subnets (public + private)
- 3 EC2 instances
- 3 Security Groups
- Internet Gateway + NAT Gateway

#### Step 5: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted.

Wait 3-5 minutes for deployment.

#### Step 6: Save IP Addresses

```bash
terraform output | tee ../deployment-ips.txt
```

Note these IPs - you'll need them next!

---

### PHASE 2: Configure Ansible (5 minutes)

#### Step 7: Auto-Update Inventory

```bash
cd ../ansible/
./update-inventory.sh
```

This script automatically:
- ✅ Gets IPs from Terraform
- ✅ Updates Ansible inventory
- ✅ Offers to update SSH config

**When prompted about SSH config**: Type `y` to automatically configure it.

#### Step 8: Update Docker Hub Username

```bash
nano group_vars/all.yml
```

Change line 4:
```yaml
dockerhub_username: "your-actual-dockerhub-username"
```

Save and exit (Ctrl+X, Y, Enter)

#### Step 9: Install Ansible Docker Collection

```bash
ansible-galaxy collection install community.docker
```

#### Step 10: Test Connectivity

```bash
ansible all -m ping
```

Expected output (all hosts return "pong"):
```
frontend-instance | SUCCESS => { "ping": "pong" }
backend-instance | SUCCESS => { "ping": "pong" }
db-instance | SUCCESS => { "ping": "pong" }
```

**If this fails**: See troubleshooting section below.

---

### PHASE 3: Deploy Applications (10-15 minutes)

#### Step 11: Install Docker on All Instances

```bash
ansible-playbook playbooks/install-docker.yml
```

This takes 2-3 minutes per instance (runs in parallel).

Expected: "Reboot message" for each host

#### Step 12: Deploy All Services

```bash
ansible-playbook playbooks/deploy-all.yml
```

This will:
1. Deploy PostgreSQL (database instance)
2. Deploy Redis + Worker (backend instance)
3. Deploy Vote + Result (frontend instance)

Takes about 5 minutes.

#### Step 13: Get Access URLs

```bash
cd ../terraform/
FRONTEND_IP=$(terraform output -raw frontend_public_ip)

echo ""
echo "=========================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "Vote App:   http://$FRONTEND_IP:80"
echo "Result App: http://$FRONTEND_IP:5001"
echo ""
```

---

### PHASE 4: Test the Application

#### Step 14: Test Vote App

Open in browser: `http://<FRONTEND_IP>:80`

1. Click "CATS" or "DOGS"
2. You should see a checkmark ✅

If no checkmark appears, see troubleshooting below.

#### Step 15: Test Result App

Open in browser: `http://<FRONTEND_IP>:5001`

You should see:
- Real-time vote counts
- Animated bar chart
- Vote percentages

#### Step 16: Verify All Services

```bash
cd ../ansible/
ansible-playbook playbooks/check-logs.yml
```

This shows logs from all containers.

---

## 🐛 Troubleshooting

### Issue: `terraform apply` fails with "key pair not found"

**Solution**: Create or specify correct key pair name

```bash
# List your key pairs
aws ec2 describe-key-pairs --region ap-northeast-2

# Update terraform.tfvars with correct name
nano terraform.tfvars
```

### Issue: `ansible all -m ping` fails

**Cause 1**: SSH key permissions

```bash
chmod 400 ~/.ssh/martin-ap-northeast-2-key.pem
```

**Cause 2**: SSH config not set up

```bash
cd ansible/
./update-inventory.sh
# Type 'y' when asked about SSH config
```

**Cause 3**: Security group doesn't allow your IP

```bash
# Get your current IP
curl ifconfig.me

# Update terraform.tfvars and redeploy
cd ../terraform/
nano terraform.tfvars  # Update my_ip
terraform apply
```

**Test connection manually**:
```bash
ssh -i ~/.ssh/martin-ap-northeast-2-key.pem ubuntu@<FRONTEND_IP>
```

### Issue: Vote app shows no checkmark

**Symptom**: You click vote but no checkmark appears

**Solution**: Redis connection issue

```bash
# SSH into frontend
ssh frontend-instance

# Check vote container logs
docker logs vote

# Check Redis connectivity
docker exec vote env | grep REDIS_HOST
# Should show backend private IP

# Test Redis connection
sudo apt update && sudo apt install -y telnet
telnet <BACKEND_PRIVATE_IP> 6379
# Should connect
```

**Fix**: Update backend IP in inventory
```bash
cd ansible/
nano inventory/hosts.yml
# Verify redis_host under [frontend] matches backend private IP
ansible-playbook playbooks/deploy-frontend.yml  # Redeploy
```

### Issue: Result app shows 0 votes

**Symptom**: Result app loads but vote count is 0

**Solution**: Worker or PostgreSQL connection issue

```bash
# SSH into backend
ssh backend-instance

# Check worker logs
docker logs worker

# Should see lines like:
#   "Connected to redis"
#   "Connected to db"
#   "Processing vote from the vote queue"

# If errors, check PostgreSQL is running on db instance
ssh db-instance
docker ps  # Should show postgres container
docker logs postgres
```

### Issue: Cannot SSH to backend or database instances

**Symptom**: `Permission denied` or `Connection timed out`

**Solution 1**: Check SSH config

```bash
cat ~/.ssh/config | grep -A5 "frontend-instance"
# Should show ProxyJump configuration
```

**Solution 2**: Manually test jump host

```bash
# Get IPs
cd terraform/
FRONTEND_IP=$(terraform output -raw frontend_public_ip)
BACKEND_IP=$(terraform output -raw backend_private_ip)

# Test jump connection
ssh -J ubuntu@$FRONTEND_IP ubuntu@$BACKEND_IP -i ~/.ssh/martin-ap-northeast-2-key.pem
```

**Solution 3**: Check security groups

```bash
# Backend SG should allow SSH from Frontend SG
# Database SG should allow SSH from Frontend SG
# Verify in AWS Console: EC2 > Security Groups
```

### Issue: Docker pull fails - "image not found"

**Solution**: Verify Docker Hub images exist

```bash
# Manually test image pull
ssh frontend-instance
docker pull your-dockerhub-username/vote:latest

# If fails: Check Docker Hub
# - Images must be public OR
# - You must be logged in: docker login
```

Update `group_vars/all.yml` with correct username:
```bash
cd ansible/
nano group_vars/all.yml
# Update dockerhub_username
```

---

## 🎯 Verification Checklist

After deployment, verify:

- [ ] All 3 EC2 instances are running (AWS Console)
- [ ] Can SSH to frontend directly
- [ ] Can SSH to backend via frontend
- [ ] Can SSH to database via frontend
- [ ] `ansible all -m ping` succeeds
- [ ] Vote app loads and accepts votes (checkmark appears)
- [ ] Result app shows vote counts
- [ ] Vote count in Result app increases when you vote

---

## 📊 Expected Timeline

| Phase | Duration | Tasks |
|-------|----------|-------|
| Phase 1 | 10-15 min | Deploy infrastructure with Terraform |
| Phase 2 | 5 min | Configure Ansible and test connectivity |
| Phase 3 | 10-15 min | Install Docker and deploy applications |
| Phase 4 | 5 min | Test and verify |
| **Total** | **30-40 min** | Complete deployment |

---

## 🔍 Useful Commands Reference

### Check Infrastructure Status

```bash
cd terraform/
terraform show
aws ec2 describe-instances --filters "Name=tag:Owner,Values=Marty McFly" --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0],PublicIpAddress,PrivateIpAddress]' --output table
```

### Check All Container Status

```bash
cd ansible/
ansible all -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" -b
```

### Check Application Logs

```bash
# All logs
cd ansible/
ansible-playbook playbooks/check-logs.yml

# Specific container
ssh frontend-instance
docker logs -f vote  # Follow logs in real-time
```

### Test Network Connectivity

```bash
cd ansible/
ansible-playbook playbooks/test-connectivity.yml
```

### Restart Everything

```bash
cd ansible/
ansible-playbook playbooks/stop-all.yml
ansible-playbook playbooks/deploy-all.yml
```

---

## 🧹 Cleanup (Destroy Everything)

When you're done testing:

```bash
# Stop all containers (optional, saves cost faster)
cd ansible/
ansible-playbook playbooks/stop-all.yml

# Destroy infrastructure
cd ../terraform/
terraform destroy
# Type: yes

# This will delete:
# - All EC2 instances
# - VPC and subnets
# - Security groups
# - Internet Gateway and NAT Gateway
# - Elastic IP
```

**Warning**: This is irreversible! Make sure you've saved any important data.

---

## 📚 Additional Resources

- [Complete Ansible Documentation](ansible/README.md)
- [SSH Bastion Setup Guide](ansible/SSH_BASTION_SETUP.md)
- [Infrastructure Analysis](TERRAFORM_ANALYSIS.md)
- [Project Overview](README.md)

---

## 🎉 Success Criteria

You've successfully completed the project when:

✅ Infrastructure deployed via Terraform
✅ All instances accessible via Ansible
✅ Docker installed on all instances
✅ All containers running
✅ Vote app accepts votes (checkmark appears)
✅ Result app shows vote tallies
✅ Votes persist across page refreshes

**Congratulations!** You've deployed a production-like multi-tier application! 🚀

---

**Need Help?** Check the detailed troubleshooting guides in:
- `ansible/README.md`
- `ansible/SSH_BASTION_SETUP.md`

Or ask your instructor during stand-up meetings!
