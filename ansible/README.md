# Ansible Configuration for Voting App Deployment

This directory contains Ansible playbooks and configuration to deploy the multi-stack voting application across AWS EC2 instances.

## 📁 Directory Structure

```
ansible/
├── ansible.cfg                 # Ansible configuration
├── inventory/
│   └── hosts.yml              # Inventory with all hosts
├── group_vars/
│   ├── all.yml                # Global variables
│   ├── frontend.yml           # Frontend-specific variables
│   ├── backend.yml            # Backend-specific variables
│   └── database.yml           # Database-specific variables
├── playbooks/
│   ├── install-docker.yml     # Install Docker on all instances
│   ├── deploy-all.yml         # Master deployment playbook
│   ├── deploy-database.yml    # Deploy PostgreSQL
│   ├── deploy-backend.yml     # Deploy Redis + Worker
│   ├── deploy-frontend.yml    # Deploy Vote + Result
│   ├── check-logs.yml         # Check container logs
│   ├── stop-all.yml           # Stop all containers
│   └── test-connectivity.yml  # Test network connectivity
└── README.md                  # This file
```

## 🚀 Quick Start Guide

### Prerequisites

1. **Ansible installed** on your local machine:
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install ansible

   # macOS
   brew install ansible
   ```

2. **Python packages**:
   ```bash
   pip3 install docker docker-compose
   ```

3. **Ansible Docker collection**:
   ```bash
   ansible-galaxy collection install community.docker
   ```

4. **AWS infrastructure deployed** using Terraform (from `../terraform/`)

5. **SSH key** available at `~/.ssh/martin-ap-northeast-2-key.pem` with proper permissions:
   ```bash
   chmod 400 ~/.ssh/martin-ap-northeast-2-key.pem
   ```

### Step 1: Configure SSH for Bastion Host Access

Since backend and database instances are in private subnets, you need to configure SSH to use the frontend instance as a jump host (bastion).

#### Option A: Using SSH Config (Recommended)

Create or edit `~/.ssh/config`:

```bash
# Frontend instance (public, acts as bastion)
Host frontend-instance
  HostName <FRONTEND_PUBLIC_IP>
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  StrictHostKeyChecking no

# Backend instance (private, accessed via frontend)
Host backend-instance
  HostName <BACKEND_PRIVATE_IP>
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyJump frontend-instance
  StrictHostKeyChecking no

# Database instance (private, accessed via frontend)
Host db-instance
  HostName <DB_PRIVATE_IP>
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyJump frontend-instance
  StrictHostKeyChecking no
```

Test the connection:
```bash
ssh frontend-instance  # Should connect directly
ssh backend-instance   # Should connect via frontend jump host
ssh db-instance        # Should connect via frontend jump host
```

#### Option B: Using Ansible Inventory (Already configured)

The `inventory/hosts.yml` file already includes `ProxyJump` configuration in `ansible_ssh_common_args`. This works automatically once you update the IP addresses.

### Step 2: Update Inventory with Real IP Addresses

After running Terraform, get the output values:

```bash
cd ../terraform
terraform output
```

Update `inventory/hosts.yml` with the actual IP addresses:
- Replace `<FRONTEND_PUBLIC_IP>` with the frontend public IP
- Replace `<BACKEND_PRIVATE_IP>` with the backend private IP
- Replace `<DB_PRIVATE_IP>` with the database private IP

### Step 3: Update Docker Hub Username

Edit `group_vars/all.yml` and replace `your-dockerhub-username` with your actual Docker Hub username:

```yaml
dockerhub_username: "your-actual-dockerhub-username"
```

### Step 4: Test Ansible Connectivity

```bash
cd ansible/
ansible all -m ping
```

Expected output:
```
frontend-instance | SUCCESS => { "ping": "pong" }
backend-instance | SUCCESS => { "ping": "pong" }
db-instance | SUCCESS => { "ping": "pong" }
```

If you get errors:
- Verify IP addresses in inventory
- Check SSH config
- Ensure security groups allow SSH (port 22)
- Verify key permissions: `chmod 400 ~/.ssh/martin-ap-northeast-2-key.pem`

### Step 5: Install Docker on All Instances

```bash
ansible-playbook playbooks/install-docker.yml
```

This will:
- Update apt packages
- Install Docker Engine and dependencies
- Install Docker SDK for Python
- Add ubuntu user to docker group
- Start and enable Docker service

### Step 6: Deploy All Services

```bash
ansible-playbook playbooks/deploy-all.yml
```

This master playbook will:
1. Deploy PostgreSQL on the database instance
2. Deploy Redis and Worker on the backend instance
3. Deploy Vote and Result apps on the frontend instance

Deployment order is critical because:
- Worker needs PostgreSQL and Redis to be running
- Result app needs PostgreSQL to be running
- Vote app needs Redis to be running

### Step 7: Verify Deployment

Check if all containers are running:
```bash
ansible-playbook playbooks/check-logs.yml
```

Test connectivity between services:
```bash
ansible-playbook playbooks/test-connectivity.yml
```

Access the applications:
- **Vote App**: `http://<FRONTEND_PUBLIC_IP>:80`
- **Result App**: `http://<FRONTEND_PUBLIC_IP>:5001`

## 🔧 Common Operations

### Check Container Logs

```bash
ansible-playbook playbooks/check-logs.yml
```

### Stop All Containers

```bash
ansible-playbook playbooks/stop-all.yml
```

### Test Service Connectivity

```bash
ansible-playbook playbooks/test-connectivity.yml
```

### Deploy Individual Tiers

```bash
# Deploy only database
ansible-playbook playbooks/deploy-database.yml

# Deploy only backend
ansible-playbook playbooks/deploy-backend.yml

# Deploy only frontend
ansible-playbook playbooks/deploy-frontend.yml
```

### SSH into Instances

```bash
# Direct SSH to frontend
ssh frontend-instance

# SSH to backend via bastion
ssh backend-instance

# SSH to database via bastion
ssh db-instance
```

### Manual Container Management

```bash
# SSH into instance
ssh frontend-instance

# Check running containers
docker ps

# View logs
docker logs vote
docker logs result

# Check environment variables
docker exec vote env | grep REDIS

# Test connectivity from inside container
docker exec -it vote bash
apt update && apt install -y telnet
telnet <BACKEND_IP> 6379
```

## 🐛 Troubleshooting

### Issue: Cannot connect to private instances

**Solution**: Verify SSH config and security groups
```bash
# Test SSH config
ssh -v backend-instance

# Check security groups allow SSH from frontend SG
# In AWS Console: EC2 > Security Groups > backend-sg
# Should have inbound rule: Port 22 from frontend-sg
```

### Issue: Vote app shows connection error

**Symptoms**: No checkmark after voting

**Solution**: Verify Redis connectivity
```bash
ssh frontend-instance
docker exec vote env | grep REDIS_HOST
telnet <REDIS_HOST> 6379
```

Check that `REDIS_HOST` points to the backend private IP.

### Issue: Result app shows zero votes

**Symptoms**: Vote count doesn't update

**Solution**: Verify PostgreSQL connectivity and Worker logs
```bash
ssh backend-instance
docker logs worker

# Check Worker can connect to both Redis and PostgreSQL
docker exec worker env | grep -E "REDIS|POSTGRES"
```

### Issue: Worker crashes or restarts

**Solution**: Check database and Redis availability
```bash
ssh backend-instance
docker logs worker

# Test connectivity
telnet <POSTGRES_HOST> 5432
telnet <REDIS_HOST> 6379
```

Worker needs both services running before it starts.

### Issue: Ansible playbook fails with "permission denied"

**Solution**: Check SSH key permissions
```bash
chmod 400 ~/.ssh/martin-ap-northeast-2-key.pem
```

### Issue: Docker pull fails

**Solution**: Verify Docker Hub credentials and image names
```bash
# Test manually
ssh frontend-instance
docker pull your-dockerhub-username/vote:latest
```

Ensure images are public or you're logged in:
```bash
docker login
```

## 🔐 Security Considerations

1. **SSH Keys**: Never commit private keys to Git
2. **Database Passwords**: Use Ansible Vault for production:
   ```bash
   ansible-vault encrypt group_vars/all.yml
   ```
3. **Security Groups**:
   - Frontend: Only allow HTTP (80) and your IP for SSH
   - Backend: Only allow Redis port (6379) from frontend SG
   - Database: Only allow PostgreSQL (5432) from backend and frontend SGs
4. **Bastion Host**: Frontend acts as bastion - only it should have public SSH access

## 📊 Architecture Overview

```
Internet
    |
    v
Frontend Instance (Public Subnet)
├── Vote App (Port 80)      → Redis (Backend:6379)
└── Result App (Port 5001)  → PostgreSQL (Database:5432)
    |
    v (Bastion/Jump Host)
    |
    +---> Backend Instance (Private Subnet)
    |     ├── Redis (Port 6379)
    |     └── Worker → Redis + PostgreSQL
    |
    +---> Database Instance (Private Subnet)
          └── PostgreSQL (Port 5432)
```

## 🎯 Next Steps

1. ✅ Deploy infrastructure with Terraform
2. ✅ Configure SSH bastion access
3. ✅ Update Ansible inventory with IPs
4. ✅ Install Docker with Ansible
5. ✅ Deploy all services
6. ✅ Test voting functionality
7. 🔄 Add monitoring (CloudWatch)
8. 🔄 Implement Load Balancer
9. 🔄 Set up CI/CD pipeline

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Module Documentation](https://docs.ansible.com/ansible/latest/collections/community/docker/)
- [AWS EC2 Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [SSH ProxyJump Documentation](https://www.redhat.com/sysadmin/ssh-proxy-bastion-proxyjump)
