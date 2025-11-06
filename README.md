# Multi-Stack DevOps Infrastructure Automation

A complete infrastructure automation project deploying a polyglot microservices voting application on AWS using Terraform and Ansible.

## 📋 Project Overview

This project demonstrates infrastructure as code (IaC) and configuration management practices by deploying a multi-tier voting application across AWS EC2 instances.

### Application Architecture

**Vote Application** (Python/Flask) → **Redis** (in-memory queue) → **Worker** (.NET) → **PostgreSQL** (persistent storage) ← **Result Application** (Node.js/Express)

### Infrastructure Architecture

- **3-Tier Architecture** across 3 EC2 instances
- **Public Subnet**: Frontend instance (Vote + Result apps)
- **Private Subnet**: Backend instance (Redis + Worker)
- **Private Subnet**: Database instance (PostgreSQL)
- **Security**: Frontend acts as bastion host for private instance access

## 🗂️ Project Structure

```
project_multistack_devops_app/
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                  # Project metadata
│   ├── provider.tf              # AWS provider configuration
│   ├── variables.tf             # Input variables
│   ├── network.tf               # VPC, subnets, routing
│   ├── security.tf              # Security groups
│   ├── instances.tf             # EC2 instances
│   ├── cloudwatch.tf            # CloudWatch monitoring
│   ├── outputs.tf               # Output values
│   └── terraform-backend/       # Remote state backend setup
│
├── ansible/                      # Configuration Management
│   ├── ansible.cfg              # Ansible configuration
│   ├── inventory/hosts.yml      # Host inventory (gitignored)
│   ├── group_vars/              # Variable definitions
│   └── playbooks/
│       ├── install-docker.yml   # Install Docker
│       ├── deploy-*-cli.yml     # Component deployment playbooks
│       ├── deploy-monitoring.yml # Prometheus/Grafana
│       ├── deploy-app-metrics.yml # Redis/Postgres exporters
│       ├── setup-cloudwatch.yml # CloudWatch Agent
│       ├── test-connectivity.yml # Network tests
│       ├── check-logs.yml       # Container logs
│       └── stop-all.yml         # Stop all containers
│
├── monitoring/                   # Monitoring & Demo Scripts
│   ├── prometheus/              # Prometheus configs
│   ├── grafana/                 # Grafana dashboards
│   ├── cloudwatch/              # CloudWatch configs
│   ├── quick-stress.sh          # Load testing (random votes)
│   ├── stress-test.sh           # Advanced load testing
│   ├── vote-cats.sh             # Vote for cats demo
│   ├── vote-dogs.sh             # Vote for dogs demo
│   ├── reset-db-simple.sh       # Database reset
│   ├── check-votes.sh           # Vote count checker
│   └── *.md                     # Monitoring documentation
│
├── presentation/                 # Project Presentation
│   ├── PRESENTATION.md          # Marp presentation
│   ├── images/                  # Presentation images
│   ├── generate-presentation.sh # PDF generator
│   └── *.md                     # Presentation guides
│
├── docs/                         # Documentation
│   ├── ANSIBLE_EXPLAINED.md     # Ansible architecture
│   ├── ANSIBLE_CONTROL_NODE.md  # Control node setup
│   ├── ANSIBLE_GALAXY_ROLES.md  # Galaxy roles info
│   ├── MONITORING_ARCHITECTURE.md # Monitoring deep dive
│   ├── COMPONENTS_GUIDE.md      # Component architecture
│   └── QUICK_REFERENCE.md       # Quick reference guide
│
└── README.md                     # This file
```

## 🚀 Quick Start Guide

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.6.0 installed
3. **Ansible** installed with Docker collection
4. **AWS CLI** configured with credentials
5. **SSH Key Pair** created in AWS (ap-northeast-2 region)
6. **Docker Hub Account** with published images

### Step 1: Configure Environment Variables

Copy the example environment file and update with your values:

```bash
cp .env.example .env
# Edit .env with your actual IP addresses after Terraform deployment
```

### Step 2: Deploy Infrastructure with Terraform

#### 2.1: Set Up Remote State Backend (Optional but Recommended)

```bash
cd terraform/terraform-backend/

# Create terraform.tfvars
cat > terraform.tfvars << EOF
aws_region = "ap-northeast-2"
project_name = "bttf-voting-app"
environment = "dev"
EOF

# Initialize and deploy
terraform init
terraform plan
terraform apply

# Note the outputs - you'll need these for the main project
terraform output
```

#### 1.2: Deploy Main Infrastructure

```bash
cd ../  # Back to terraform/ directory

# Create terraform.tfvars
cat > terraform.tfvars << EOF
aws_region = "ap-northeast-2"
key_pair_name = "martin-ap-northeast-2-key"
my_ip = "YOUR_PUBLIC_IP/32"
EOF

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply

# Save the outputs
terraform output > ../deployment-ips.txt
```

Your infrastructure is now created! Note the IP addresses from the output.

### Step 2: Configure Ansible and Deploy Applications

#### 2.1: Automatic Inventory Update (Recommended)

```bash
cd ../ansible/

# Run the update script
./update-inventory.sh
```

This script will:
- Extract IP addresses from Terraform state
- Update the Ansible inventory
- Optionally update your SSH config

#### 2.2: Manual Inventory Update (Alternative)

If you prefer manual setup:

```bash
# Get IPs from Terraform
cd ../terraform/
terraform output

# Update ansible/inventory/hosts.yml with the IPs
cd ../ansible/
nano inventory/hosts.yml
# Replace <FRONTEND_PUBLIC_IP>, <BACKEND_PRIVATE_IP>, <DB_PRIVATE_IP>

# Update group_vars/all.yml with your Docker Hub username
nano group_vars/all.yml
# Change: dockerhub_username: "your-dockerhub-username"
```

#### 2.3: Configure SSH Bastion Access

See `ansible/SSH_BASTION_SETUP.md` for detailed instructions.

Quick version - add to `~/.ssh/config`:

```
Host frontend-instance
  HostName <FRONTEND_PUBLIC_IP>
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  StrictHostKeyChecking no

Host backend-instance
  HostName <BACKEND_PRIVATE_IP>
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyJump frontend-instance
  StrictHostKeyChecking no

Host db-instance
  HostName <DB_PRIVATE_IP>
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyJump frontend-instance
  StrictHostKeyChecking no
```

#### 2.4: Test Ansible Connectivity

```bash
cd ansible/

# Install Ansible Docker collection
ansible-galaxy collection install community.docker

# Test connectivity
ansible all -m ping
```

Expected: All hosts return "pong"

#### 2.5: Install Docker on All Instances

```bash
ansible-playbook playbooks/install-docker.yml
```

This takes 2-3 minutes per instance.

#### 2.6: Deploy All Applications

```bash
ansible-playbook playbooks/deploy-all.yml
```

This will deploy:
1. PostgreSQL on database instance
2. Redis and Worker on backend instance
3. Vote and Result apps on frontend instance

### Step 3: Access and Test the Application

```bash
# Get the frontend public IP
cd ../terraform/
FRONTEND_IP=$(terraform output -raw frontend_public_ip)

echo "Vote App:   http://$FRONTEND_IP:80"
echo "Result App: http://$FRONTEND_IP:5001"
```

Open your browser:
- **Vote App**: Cast a vote for Cats or Dogs
- **Result App**: See real-time vote tallies

## 🔧 Common Operations

### Check Application Logs

```bash
cd ansible/
ansible-playbook playbooks/check-logs.yml
```

### Test Service Connectivity

```bash
ansible-playbook playbooks/test-connectivity.yml
```

### Restart Services

```bash
# Stop all containers
ansible-playbook playbooks/stop-all.yml

# Redeploy
ansible-playbook playbooks/deploy-all.yml
```

### SSH into Instances

```bash
# Frontend (direct)
ssh frontend-instance

# Backend (via bastion)
ssh backend-instance

# Database (via bastion)
ssh db-instance
```

### Check Container Status

```bash
ssh frontend-instance
docker ps
docker logs vote
docker logs result
```

## 🐛 Troubleshooting

### Vote App Not Working

**Symptom**: No checkmark after voting

**Solution**: Check Redis connectivity
```bash
ssh frontend-instance
docker exec vote env | grep REDIS
telnet <BACKEND_IP> 6379
```

### Result App Shows Zero Votes

**Symptom**: Vote count doesn't update

**Solution**: Check Worker logs
```bash
ssh backend-instance
docker logs worker
```

Verify Worker can connect to both Redis and PostgreSQL.

### Cannot SSH to Private Instances

**Solution**: Check SSH config and security groups

```bash
# Test SSH config
ssh -v backend-instance

# Verify security groups in AWS Console:
# Backend SG should allow SSH (22) from Frontend SG
```

### Ansible Connection Failed

**Solution**: Verify inventory and SSH key permissions

```bash
chmod 400 ~/.ssh/martin-ap-northeast-2-key.pem
ansible all -m ping -vvv  # Verbose mode for debugging
```

See `ansible/README.md` for detailed troubleshooting.

## 🔐 Security Considerations

1. **SSH Access**: Restricted to your IP only (via `my_ip` variable)
2. **Private Subnets**: Backend and database not exposed to internet
3. **Security Groups**: Proper port restrictions between tiers
4. **Bastion Host**: Frontend instance for secure access to private instances
5. **State Files**: Stored in S3 with encryption and versioning
6. **Secrets**: Never commit `terraform.tfvars` or SSH keys

## 🎯 Project Learning Outcomes

- ✅ Infrastructure as Code with Terraform
- ✅ Multi-tier AWS architecture (VPC, subnets, security groups)
- ✅ Configuration Management with Ansible
- ✅ Docker containerization and orchestration
- ✅ Bastion host and SSH jump host configuration
- ✅ Microservices communication patterns
- ✅ DevOps best practices and automation

## 📚 Documentation

- [Ansible README](ansible/README.md) - Complete Ansible guide
- [SSH Bastion Setup](ansible/SSH_BASTION_SETUP.md) - SSH configuration
- [Terraform Analysis](TERRAFORM_ANALYSIS.md) - Infrastructure analysis

## 🚧 Future Enhancements

- [ ] Add Application Load Balancer (ALB)
- [ ] Multi-AZ deployment for high availability
- [ ] CloudWatch monitoring and alerts
- [ ] Auto Scaling Groups
- [ ] HTTPS with SSL certificates
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Migrate to managed services (RDS, ElastiCache)

## 📝 Project Notes

**Technologies Used**:
- **Infrastructure**: Terraform, AWS (EC2, VPC, Security Groups)
- **Configuration**: Ansible, Docker
- **Applications**: Python (Flask), Node.js (Express), .NET (Worker), Redis, PostgreSQL

**Region**: ap-northeast-2 (Seoul)
**Environment**: Development

## 🤝 Contributing

This is a learning project for the IronHack DevOps Bootcamp. Feel free to use it as a reference for your own projects!

## 📄 License

Educational project - free to use and modify.

---

**Author**: Marty McFly
**Project**: IronHack DevOps Bootcamp - Project 1
**Date**: November 2024
