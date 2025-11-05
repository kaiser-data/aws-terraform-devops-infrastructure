# ✈️ Pre-Flight Checklist - Everything You Need

Complete checklist of prerequisites and setup steps before running the deployment.

## ✅ 1. System Prerequisites

### Install Required Software

```bash
# Check what you have
terraform --version  # Need >= 1.6.0
ansible --version    # Need >= 2.9
aws --version        # Need >= 2.x
python3 --version    # Need >= 3.8
pip3 --version
```

### Install Missing Tools

**Terraform** (if needed):
```bash
# Ubuntu/Debian
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# macOS
brew install terraform
```

**Ansible** (if needed):
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y ansible

# macOS
brew install ansible
```

**AWS CLI** (if needed):
```bash
# Ubuntu/Debian
sudo apt install -y awscli

# macOS
brew install awscli
```

## ✅ 2. Ansible Collections

**CRITICAL**: Install the Docker collection for Ansible

```bash
ansible-galaxy collection install community.docker
```

Verify installation:
```bash
ansible-galaxy collection list | grep docker
```

Should show:
```
community.docker    3.x.x
```

## ✅ 3. Python Dependencies

```bash
# Required for Ansible Docker modules
pip3 install docker docker-compose

# Verify
python3 -c "import docker; print('Docker SDK OK')"
```

## ✅ 4. AWS Configuration

### Configure AWS Credentials

```bash
aws configure
```

Enter:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `ap-northeast-2`
- Default output format: `json`

### Verify AWS Access

```bash
aws sts get-caller-identity
aws ec2 describe-regions --region ap-northeast-2
```

## ✅ 5. SSH Key Setup

### Check Your Key Exists

```bash
# Replace with your actual key name
ls -la ~/.ssh/martin-ap-northeast-2-key.pem
```

### Set Correct Permissions

```bash
chmod 400 ~/.ssh/martin-ap-northeast-2-key.pem
```

### Verify in AWS

```bash
aws ec2 describe-key-pairs --region ap-northeast-2 --key-names martin-ap-northeast-2-key
```

## ✅ 6. Docker Hub Images

### Verify Images Exist

Your Docker Hub account must have these images:
- `your-username/vote:latest`
- `your-username/result:latest`
- `your-username/worker:latest`

Check on Docker Hub or:
```bash
docker pull your-username/vote:latest
docker pull your-username/result:latest
docker pull your-username/worker:latest
```

If images don't exist, you need to build and push them first!

## ✅ 7. Terraform Configuration

### Update terraform.tfvars

```bash
cd terraform/

# Check if file exists
cat terraform.tfvars
```

Should contain:
```hcl
aws_region = "ap-northeast-2"
key_pair_name = "martin-ap-northeast-2-key"  # YOUR KEY NAME
my_ip = "YOUR_IP/32"
```

### Get Your Current IP

```bash
curl ifconfig.me
# Example: 203.0.113.45

# Update terraform.tfvars with YOUR_IP/32
# Example: my_ip = "203.0.113.45/32"
```

## ✅ 8. Ansible Configuration

### Update Docker Hub Username

```bash
cd ansible/

nano group_vars/all.yml
```

Change line 4:
```yaml
dockerhub_username: "YOUR-DOCKERHUB-USERNAME"  # CHANGE THIS!
```

## 🧪 Quick Validation Script

Run this to check everything:

```bash
cat > /tmp/preflight-check.sh << 'EOF'
#!/bin/bash

echo "=========================================="
echo "Pre-Flight Validation Check"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 installed${NC}"
        $1 --version 2>&1 | head -1
    else
        echo -e "${RED}❌ $1 NOT installed${NC}"
        return 1
    fi
    echo ""
}

echo "1. Checking required commands..."
check_command terraform
check_command ansible
check_command aws
check_command python3
check_command pip3

echo "2. Checking Ansible collections..."
if ansible-galaxy collection list | grep -q community.docker; then
    echo -e "${GREEN}✅ community.docker collection installed${NC}"
else
    echo -e "${RED}❌ community.docker collection NOT installed${NC}"
    echo "   Run: ansible-galaxy collection install community.docker"
fi
echo ""

echo "3. Checking Python Docker SDK..."
if python3 -c "import docker" 2>/dev/null; then
    echo -e "${GREEN}✅ Docker SDK for Python installed${NC}"
else
    echo -e "${RED}❌ Docker SDK NOT installed${NC}"
    echo "   Run: pip3 install docker"
fi
echo ""

echo "4. Checking AWS credentials..."
if aws sts get-caller-identity &>/dev/null; then
    echo -e "${GREEN}✅ AWS credentials configured${NC}"
    aws sts get-caller-identity
else
    echo -e "${RED}❌ AWS credentials NOT configured${NC}"
    echo "   Run: aws configure"
fi
echo ""

echo "5. Checking SSH key..."
if [ -f ~/.ssh/martin-ap-northeast-2-key.pem ]; then
    echo -e "${GREEN}✅ SSH key exists${NC}"
    PERMS=$(stat -c %a ~/.ssh/martin-ap-northeast-2-key.pem 2>/dev/null || stat -f %A ~/.ssh/martin-ap-northeast-2-key.pem 2>/dev/null)
    if [ "$PERMS" = "400" ]; then
        echo -e "${GREEN}✅ SSH key has correct permissions (400)${NC}"
    else
        echo -e "${RED}⚠️  SSH key permissions: $PERMS (should be 400)${NC}"
        echo "   Run: chmod 400 ~/.ssh/martin-ap-northeast-2-key.pem"
    fi
else
    echo -e "${RED}❌ SSH key NOT found${NC}"
fi
echo ""

echo "6. Checking terraform.tfvars..."
if [ -f terraform/terraform.tfvars ]; then
    echo -e "${GREEN}✅ terraform.tfvars exists${NC}"
    if grep -q "my_ip" terraform/terraform.tfvars; then
        echo -e "${GREEN}✅ my_ip configured${NC}"
    else
        echo -e "${RED}❌ my_ip NOT configured${NC}"
    fi
else
    echo -e "${RED}❌ terraform.tfvars NOT found${NC}"
fi
echo ""

echo "7. Checking Ansible Docker Hub username..."
if [ -f ansible/group_vars/all.yml ]; then
    if grep -q "your-dockerhub-username" ansible/group_vars/all.yml; then
        echo -e "${RED}❌ Docker Hub username NOT updated (still default)${NC}"
        echo "   Edit: ansible/group_vars/all.yml"
    else
        echo -e "${GREEN}✅ Docker Hub username configured${NC}"
    fi
else
    echo -e "${RED}❌ ansible/group_vars/all.yml NOT found${NC}"
fi
echo ""

echo "=========================================="
echo "Pre-Flight Check Complete!"
echo "=========================================="
EOF

chmod +x /tmp/preflight-check.sh
/tmp/preflight-check.sh
```

## 📋 Step-by-Step Run Order

Once everything above is ✅, follow this order:

### 1. Deploy Infrastructure

```bash
cd terraform/
terraform init              # First time only
terraform plan              # Review what will be created
terraform apply             # Deploy (auto-generates Ansible files!)
```

### 2. Configure SSH

```bash
# Add SSH config
cat ../ansible/ssh_config >> ~/.ssh/config

# Verify
ssh frontend-instance exit  # Should connect and immediately exit
```

### 3. Test Ansible

```bash
cd ../ansible/
ansible all -m ping
```

Should see all hosts return "pong"

### 4. Install Docker

```bash
ansible-playbook playbooks/install-docker.yml
```

Takes 3-5 minutes

### 5. Deploy Applications

```bash
ansible-playbook playbooks/deploy-all.yml
```

Takes 5-10 minutes

### 6. Test Applications

```bash
# Get IP
FRONTEND_IP=$(cd ../terraform && terraform output -raw frontend_public_ip)

# Open in browser
echo "Vote:   http://$FRONTEND_IP:80"
echo "Result: http://$FRONTEND_IP:5001"
```

## ❌ Common Missing Items

| Issue | Check | Fix |
|-------|-------|-----|
| Ansible Docker module fails | `ansible-galaxy collection list` | `ansible-galaxy collection install community.docker` |
| Python import error | `python3 -c "import docker"` | `pip3 install docker` |
| AWS access denied | `aws sts get-caller-identity` | `aws configure` |
| SSH permission denied | `ls -la ~/.ssh/*.pem` | `chmod 400 ~/.ssh/key.pem` |
| Terraform key not found | AWS Console → EC2 → Key Pairs | Verify key name matches |
| Docker images not found | Docker Hub | Build and push images first |
| Ansible cannot reach hosts | Security group rules | Verify my_ip in terraform.tfvars |

## 🚨 Critical Pre-Deployment

Before running `ansible-playbook`:

1. ✅ Run the validation script above
2. ✅ All checks should be green
3. ✅ `ansible all -m ping` succeeds
4. ✅ Docker images exist on Docker Hub

## 📞 Quick Help Commands

```bash
# Terraform
cd terraform/ && terraform validate

# Ansible
cd ansible/ && ansible-inventory --list
cd ansible/ && ansible all -m ping -vvv  # Verbose mode

# AWS
aws ec2 describe-instances --region ap-northeast-2 --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]' --output table

# SSH
ssh -v frontend-instance  # Verbose SSH for debugging
```

## ✅ Final Checklist

- [ ] Terraform installed and working
- [ ] Ansible installed and working
- [ ] AWS CLI configured with credentials
- [ ] `ansible-galaxy collection install community.docker` completed
- [ ] `pip3 install docker` completed
- [ ] SSH key exists with 400 permissions
- [ ] terraform.tfvars configured with correct key_pair_name and my_ip
- [ ] ansible/group_vars/all.yml updated with Docker Hub username
- [ ] Docker images exist on Docker Hub (vote, result, worker)

**Once all checked**: Run the validation script, then proceed with deployment!
