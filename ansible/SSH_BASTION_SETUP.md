# SSH Bastion Host Configuration Guide

## Overview

Since your backend and database EC2 instances are in **private subnets** (no public IP), you cannot SSH into them directly from the internet. The **frontend instance** acts as a **bastion host** (jump host) to access private instances.

## Architecture

```
Your Computer
     |
     | SSH (Public Internet)
     v
Frontend Instance (Public Subnet)
     |
     | SSH (Private Network)
     +---> Backend Instance (Private Subnet)
     |
     +---> Database Instance (Private Subnet)
```

## Method 1: SSH Config File (Recommended)

This method is cleaner and works automatically with Ansible.

### Step 1: Create SSH Config

Edit or create `~/.ssh/config`:

```bash
nano ~/.ssh/config
```

Add the following configuration:

```
# Frontend instance - publicly accessible (Bastion Host)
Host frontend-instance
  HostName <FRONTEND_PUBLIC_IP>
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ServerAliveInterval 60
  ServerAliveCountMax 3

# Backend instance - private subnet (via bastion)
Host backend-instance
  HostName <BACKEND_PRIVATE_IP>
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyJump frontend-instance
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

# Database instance - private subnet (via bastion)
Host db-instance
  HostName <DB_PRIVATE_IP>
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyJump frontend-instance
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

### Step 2: Get IP Addresses from Terraform

```bash
cd terraform/
terraform output
```

Output will show:
```
frontend_public_ip = "3.35.123.45"
backend_private_ip = "10.0.2.10"
database_private_ip = "10.0.2.20"
```

### Step 3: Update SSH Config

Replace the placeholders in `~/.ssh/config`:
- `<FRONTEND_PUBLIC_IP>` → `3.35.123.45`
- `<BACKEND_PRIVATE_IP>` → `10.0.2.10`
- `<DB_PRIVATE_IP>` → `10.0.2.20`

### Step 4: Test SSH Access

```bash
# Test direct access to frontend
ssh frontend-instance

# Test jump access to backend
ssh backend-instance

# Test jump access to database
ssh db-instance
```

All three should connect successfully.

### Step 5: Test with Ansible

```bash
cd ../ansible/
ansible all -m ping
```

Expected output:
```
frontend-instance | SUCCESS => { "ping": "pong" }
backend-instance | SUCCESS => { "ping": "pong" }
db-instance | SUCCESS => { "ping": "pong" }
```

## Method 2: Manual SSH Jump (Without Config File)

If you don't want to use SSH config, you can manually specify the jump host:

### SSH to Backend

```bash
ssh -J ubuntu@<FRONTEND_PUBLIC_IP> ubuntu@<BACKEND_PRIVATE_IP> -i ~/.ssh/martin-ap-northeast-2-key.pem
```

### SSH to Database

```bash
ssh -J ubuntu@<FRONTEND_PUBLIC_IP> ubuntu@<DB_PRIVATE_IP> -i ~/.ssh/martin-ap-northeast-2-key.pem
```

### Using with Ansible

Update `inventory/hosts.yml` to include the ProxyCommand:

```yaml
backend:
  hosts:
    backend-instance:
      ansible_host: <BACKEND_PRIVATE_IP>
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/martin-ap-northeast-2-key.pem
      ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -i ~/.ssh/martin-ap-northeast-2-key.pem ubuntu@<FRONTEND_PUBLIC_IP>"'
```

## Method 3: SSH Agent Forwarding

This method forwards your local SSH key through the bastion.

### Step 1: Add Key to SSH Agent

```bash
# Start SSH agent
eval $(ssh-agent)

# Add your key
ssh-add ~/.ssh/martin-ap-northeast-2-key.pem

# Verify key is added
ssh-add -l
```

### Step 2: SSH with Agent Forwarding

```bash
# SSH to frontend with agent forwarding
ssh -A ubuntu@<FRONTEND_PUBLIC_IP>

# From frontend, SSH to backend
ssh ubuntu@<BACKEND_PRIVATE_IP>

# From frontend, SSH to database
ssh ubuntu@<DB_PRIVATE_IP>
```

## Troubleshooting

### Issue: "Permission denied (publickey)"

**Solution 1**: Check key permissions
```bash
chmod 400 ~/.ssh/martin-ap-northeast-2-key.pem
ls -la ~/.ssh/martin-ap-northeast-2-key.pem
# Should show: -r-------- (400)
```

**Solution 2**: Verify the key is correct
```bash
ssh-keygen -y -f ~/.ssh/martin-ap-northeast-2-key.pem
# Should display the public key
```

**Solution 3**: Check AWS key pair name matches
```bash
cd ../terraform/
terraform output | grep key_pair
# Should show: martin-ap-northeast-2-key
```

### Issue: "Connection timed out"

**Solution 1**: Check security groups

Frontend security group should allow:
- Inbound SSH (22) from your IP
- Outbound all traffic

Backend security group should allow:
- Inbound SSH (22) from frontend security group

**Solution 2**: Verify instance is running
```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=*frontend*" --query 'Reservations[].Instances[].State.Name'
```

### Issue: "Host key verification failed"

**Solution**: Disable strict host checking (already in config above)
```bash
# Or manually:
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@<IP>
```

### Issue: ProxyJump not working

**Cause**: OpenSSH version < 7.3

**Solution**: Use ProxyCommand instead
```
Host backend-instance
  HostName <BACKEND_PRIVATE_IP>
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyCommand ssh -W %h:%p frontend-instance
```

## Security Best Practices

### 1. Restrict Frontend SSH Access

Only allow SSH from your IP in the security group:

```hcl
# In terraform/security.tf
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["<YOUR_IP>/32"]  # Only your IP
}
```

### 2. Use Dedicated Bastion Host

For production, create a separate bastion host:

```
Internet → Bastion Host → Private Instances
```

Not:
```
Internet → Frontend App → Private Instances
```

### 3. Enable SSH Session Logging

On the bastion host, enable logging:

```bash
sudo bash -c 'cat >> /etc/ssh/sshd_config << EOF
# SSH Session Logging
Match User ubuntu
    ForceCommand /usr/bin/log-session
EOF'
```

### 4. Use AWS Systems Manager Session Manager

Alternative to SSH bastion:

```bash
# Connect without SSH
aws ssm start-session --target <INSTANCE_ID>
```

This requires:
- SSM Agent on instances
- IAM role with SSM permissions
- No inbound SSH rules needed

## Testing Your Setup

### Complete Test Sequence

```bash
# 1. Test frontend (public)
echo "Testing frontend access..."
ssh frontend-instance "echo 'Frontend OK'"

# 2. Test backend (private via jump)
echo "Testing backend access..."
ssh backend-instance "echo 'Backend OK'"

# 3. Test database (private via jump)
echo "Testing database access..."
ssh db-instance "echo 'Database OK'"

# 4. Test Ansible connectivity
echo "Testing Ansible..."
cd ansible/
ansible all -m ping

# 5. Test multi-hop
echo "Testing network reachability..."
ssh frontend-instance "ping -c 2 <BACKEND_PRIVATE_IP>"
ssh backend-instance "ping -c 2 <DB_PRIVATE_IP>"

echo "All tests completed!"
```

## Quick Reference

### Get IPs from Terraform
```bash
cd terraform/
terraform output frontend_public_ip
terraform output backend_private_ip
terraform output database_private_ip
```

### Update Ansible Inventory
```bash
cd ../ansible/
nano inventory/hosts.yml
# Replace <FRONTEND_PUBLIC_IP>, <BACKEND_PRIVATE_IP>, <DB_PRIVATE_IP>
```

### Update SSH Config
```bash
nano ~/.ssh/config
# Add configuration from Method 1 above
```

### Test Everything
```bash
ssh frontend-instance
ssh backend-instance
ssh db-instance
cd ansible/ && ansible all -m ping
```

## Summary

✅ **Frontend Instance** = Bastion/Jump Host (public IP)
✅ **Backend Instance** = Private (access via frontend)
✅ **Database Instance** = Private (access via frontend)
✅ **SSH Config** = ProxyJump makes it seamless
✅ **Ansible** = Works automatically with SSH config

You're now ready to deploy with Ansible! 🚀
