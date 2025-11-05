# 🔧 Project Setup Guide - Zero to Deployed

This guide shows how to set up the project from scratch with **no hardcoded personal information**.

## 📦 What You Get

This project is designed to be **cloned and shared** without exposing any personal data:

- ✅ No hardcoded AWS credentials
- ✅ No hardcoded Docker Hub username
- ✅ No hardcoded SSH keys
- ✅ No hardcoded IP addresses
- ✅ Everything uses example files and environment variables

## 🚀 Quick Setup (Automated)

### Option 1: Interactive Setup Script (Recommended)

```bash
# Clone the repository
git clone <your-repo-url>
cd project_multistack_devops_app

# Run the setup script
./setup.sh
```

The script will:
1. Create `.env` with your personal settings
2. Create `terraform/terraform.tfvars` from your inputs
3. Create `ansible/group_vars/all.yml` with your Docker Hub username
4. Guide you through next steps

**That's it!** Your project is configured.

### Option 2: Manual Setup

If you prefer manual setup:

```bash
# 1. Copy example files
cp .env.example .env
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
cp ansible/group_vars/all.yml.example ansible/group_vars/all.yml

# 2. Edit each file with your values
nano .env
nano terraform/terraform.tfvars
nano ansible/group_vars/all.yml
```

## 📝 Configuration Files Explained

### 1. `.env` - Environment Variables

**Location**: Root directory
**Purpose**: Central configuration for all tools
**Git**: Ignored (never committed)

```bash
# Example content
export AWS_REGION="ap-northeast-2"
export TF_VAR_key_pair_name="your-key-name"
export TF_VAR_my_ip="203.0.113.45/32"
export DOCKERHUB_USERNAME="yourusername"
```

**Usage**:
```bash
source .env  # Load variables before running terraform/ansible
```

### 2. `terraform/terraform.tfvars` - Terraform Variables

**Location**: `terraform/terraform.tfvars`
**Purpose**: Terraform-specific configuration
**Git**: Ignored (never committed)
**Auto-generated**: By setup.sh or manually created

```hcl
aws_region    = "ap-northeast-2"
key_pair_name = "your-key-name"
my_ip         = "203.0.113.45/32"
```

### 3. `ansible/group_vars/all.yml` - Ansible Variables

**Location**: `ansible/group_vars/all.yml`
**Purpose**: Ansible configuration
**Git**: Ignored (never committed)
**Auto-generated**: By setup.sh or manually created

```yaml
dockerhub_username: "yourusername"
postgres_password: "secure_password"
```

### 4. Auto-Generated Files (Don't Edit)

These are **automatically generated** by Terraform:

- `ansible/inventory/hosts.yml` - Created from Terraform outputs
- `ansible/group_vars/terraform_generated.yml` - IP addresses
- `ansible/ssh_config` - SSH bastion configuration

**All are gitignored** and regenerated on each `terraform apply`

## 🔐 Security Best Practices

### What's Safe to Commit

✅ Safe (example files):
- `.env.example`
- `terraform/terraform.tfvars.example`
- `ansible/group_vars/all.yml.example`
- All `.tf` files
- All playbook `.yml` files
- Documentation `.md` files

❌ Never commit:
- `.env`
- `terraform/terraform.tfvars`
- `ansible/group_vars/all.yml`
- `*.tfstate` files
- `*.pem` or `*.key` files
- Any file with real IPs, passwords, or credentials

### Using Ansible Vault (Optional)

For extra security with passwords:

```bash
# Encrypt sensitive variables
ansible-vault encrypt ansible/group_vars/all.yml

# Use vault password when running playbooks
ansible-playbook --ask-vault-pass playbooks/deploy-all.yml
```

## 📋 Step-by-Step Deployment

### Step 1: Clone and Setup

```bash
# Clone repository
git clone <repo-url>
cd project_multistack_devops_app

# Run setup
./setup.sh
```

### Step 2: Load Environment

```bash
# Load environment variables
source .env

# Verify
echo $DOCKERHUB_USERNAME
echo $TF_VAR_key_pair_name
```

### Step 3: Install Prerequisites

```bash
# Python packages
pip3 install docker

# Ansible collections
ansible-galaxy collection install community.docker
```

### Step 4: Deploy Infrastructure

```bash
cd terraform/

# Initialize Terraform (first time only)
terraform init

# Review plan
terraform plan

# Deploy (auto-generates Ansible files!)
terraform apply
```

**What happens**:
- ✅ Creates AWS infrastructure
- ✅ Generates `ansible/inventory/hosts.yml` with real IPs
- ✅ Generates `ansible/group_vars/terraform_generated.yml`
- ✅ Generates `ansible/ssh_config`

### Step 5: Configure SSH

```bash
# Add SSH config for bastion access
cat ../ansible/ssh_config >> ~/.ssh/config
```

### Step 6: Test Connectivity

```bash
cd ../ansible/

# Test Ansible can reach all hosts
ansible all -m ping
```

Expected: All 3 hosts return "pong"

### Step 7: Deploy Applications

```bash
# Install Docker on all instances
ansible-playbook playbooks/install-docker.yml

# Deploy all services
ansible-playbook playbooks/deploy-all.yml
```

### Step 8: Access Applications

```bash
# Get frontend IP
cd ../terraform/
FRONTEND_IP=$(terraform output -raw frontend_public_ip)

echo "Vote:   http://$FRONTEND_IP:80"
echo "Result: http://$FRONTEND_IP:5001"
```

## 🔄 Working as a Team

### Sharing the Project

When sharing with teammates:

1. **Commit**: Only example files and code
2. **Share**: Repository URL
3. **Team member runs**: `./setup.sh` with their own values
4. **Everyone has**: Their own `.env` and config files (gitignored)

### Using Different AWS Accounts

Each team member can use their own AWS account:

```bash
# Team member 1
./setup.sh
# Enters their AWS key, IP, Docker Hub username

# Team member 2
./setup.sh
# Enters different AWS key, IP, Docker Hub username
```

Both deploy independently without conflicts!

## 🗂️ Project Structure (Shareable)

```
project_multistack_devops_app/
├── .env.example                    ← Commit this (example)
├── .env                            ← Gitignored (your values)
├── setup.sh                        ← Commit this (setup script)
├── terraform/
│   ├── *.tf                        ← Commit these (infrastructure code)
│   ├── terraform.tfvars.example    ← Commit this (example)
│   └── terraform.tfvars            ← Gitignored (your values)
├── ansible/
│   ├── playbooks/                  ← Commit these (automation)
│   ├── group_vars/
│   │   ├── all.yml.example         ← Commit this (example)
│   │   └── all.yml                 ← Gitignored (your values)
│   └── inventory/
│       └── hosts.yml               ← Gitignored (auto-generated)
└── docs/                           ← Commit these (documentation)
```

## 🎯 Environment Variable Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `TF_VAR_aws_region` | AWS region | `ap-northeast-2` |
| `TF_VAR_key_pair_name` | AWS SSH key name | `my-key` |
| `TF_VAR_my_ip` | Your public IP | `203.0.113.45/32` |
| `DOCKERHUB_USERNAME` | Docker Hub username | `johndoe` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Database password | `postgres` |
| `AWS_PROFILE` | AWS CLI profile | `default` |
| `SSH_KEY_PATH` | SSH key location | `~/.ssh/key.pem` |

## 🧪 Testing Your Setup

### Verification Checklist

```bash
# 1. Check environment loaded
source .env
env | grep TF_VAR

# 2. Check Terraform config
cat terraform/terraform.tfvars

# 3. Check Ansible config
cat ansible/group_vars/all.yml

# 4. Verify no secrets in git
git status
# Should NOT show .env, terraform.tfvars, or all.yml
```

### Quick Test Deployment

```bash
# Full test deployment
source .env
cd terraform/ && terraform apply -auto-approve
cd ../ansible/
cat ssh_config >> ~/.ssh/config
ansible all -m ping
ansible-playbook playbooks/install-docker.yml
ansible-playbook playbooks/deploy-all.yml
```

## 🛠️ Updating Configuration

### Change AWS Region

```bash
# Edit .env
nano .env
# Update: export TF_VAR_aws_region="us-east-1"

# Reload
source .env

# Redeploy
cd terraform/
terraform apply
```

### Change Docker Hub Username

```bash
# Edit Ansible vars
nano ansible/group_vars/all.yml
# Update: dockerhub_username: "newusername"

# Redeploy applications
cd ansible/
ansible-playbook playbooks/deploy-all.yml
```

## 📚 Additional Resources

- [Quick Start Guide](QUICKSTART.md) - Fast deployment guide
- [Automated Workflow](AUTOMATED_WORKFLOW.md) - Terraform → Ansible automation
- [Pre-flight Checklist](PREFLIGHT_CHECKLIST.md) - Prerequisites check
- [Ansible Documentation](ansible/README.md) - Detailed Ansible guide
- [SSH Bastion Setup](ansible/SSH_BASTION_SETUP.md) - SSH configuration

## 🎉 Summary

**Before**: Hardcoded usernames, IPs, credentials
**After**: Clean, shareable, team-friendly project

✅ Clone repository
✅ Run `./setup.sh`
✅ Deploy with `terraform apply`
✅ No personal info committed!

**Your project is now production-ready and shareable!** 🚀
