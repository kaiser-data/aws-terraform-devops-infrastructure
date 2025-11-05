#!/bin/bash
# Script to automatically update Ansible inventory with Terraform outputs

set -e

echo "=========================================="
echo "Ansible Inventory Auto-Update Script"
echo "=========================================="
echo ""

# Check if terraform directory exists
if [ ! -d "../terraform" ]; then
    echo "❌ Error: terraform directory not found!"
    echo "Make sure you're running this from the ansible/ directory"
    exit 1
fi

# Check if terraform.tfstate exists
if [ ! -f "../terraform/terraform.tfstate" ]; then
    echo "❌ Error: terraform.tfstate not found!"
    echo "Run 'terraform apply' first to create infrastructure"
    exit 1
fi

echo "📡 Getting IP addresses from Terraform..."
cd ../terraform

# Get IPs from Terraform output
FRONTEND_PUBLIC_IP=$(terraform output -raw frontend_public_ip 2>/dev/null)
BACKEND_PRIVATE_IP=$(terraform output -raw backend_private_ip 2>/dev/null)
DATABASE_PRIVATE_IP=$(terraform output -raw database_private_ip 2>/dev/null)

cd ../ansible

if [ -z "$FRONTEND_PUBLIC_IP" ] || [ -z "$BACKEND_PRIVATE_IP" ] || [ -z "$DATABASE_PRIVATE_IP" ]; then
    echo "❌ Error: Could not retrieve IP addresses from Terraform"
    echo "Make sure your infrastructure is deployed"
    exit 1
fi

echo "✅ Retrieved IP addresses:"
echo "   Frontend (Public):  $FRONTEND_PUBLIC_IP"
echo "   Backend (Private):  $BACKEND_PRIVATE_IP"
echo "   Database (Private): $DATABASE_PRIVATE_IP"
echo ""

# Backup existing inventory
if [ -f "inventory/hosts.yml" ]; then
    cp inventory/hosts.yml inventory/hosts.yml.backup
    echo "📦 Backed up existing inventory to hosts.yml.backup"
fi

# Update inventory file
echo "📝 Updating inventory/hosts.yml..."
sed -i "s/<FRONTEND_PUBLIC_IP>/$FRONTEND_PUBLIC_IP/g" inventory/hosts.yml
sed -i "s/<BACKEND_PRIVATE_IP>/$BACKEND_PRIVATE_IP/g" inventory/hosts.yml
sed -i "s/<DB_PRIVATE_IP>/$DATABASE_PRIVATE_IP/g" inventory/hosts.yml

# Update SSH config if it exists
SSH_CONFIG="$HOME/.ssh/config"
echo ""
echo "🔧 SSH Config Setup"
echo "===================="

if [ -f "$SSH_CONFIG" ]; then
    echo "⚠️  SSH config exists at $SSH_CONFIG"
    echo "You may want to manually add or update the following:"
else
    echo "ℹ️  Creating SSH config at $SSH_CONFIG"
fi

echo ""
echo "Add this to $SSH_CONFIG:"
echo "----------------------------"
cat << EOF
# Voting App Infrastructure
Host frontend-instance
  HostName $FRONTEND_PUBLIC_IP
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  StrictHostKeyChecking no

Host backend-instance
  HostName $BACKEND_PRIVATE_IP
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyJump frontend-instance
  StrictHostKeyChecking no

Host db-instance
  HostName $DATABASE_PRIVATE_IP
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyJump frontend-instance
  StrictHostKeyChecking no
EOF
echo "----------------------------"
echo ""

# Offer to automatically update SSH config
read -p "Would you like to automatically append this to your SSH config? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup SSH config if it exists
    if [ -f "$SSH_CONFIG" ]; then
        cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✅ Backed up SSH config"
    fi

    # Append to SSH config
    cat >> "$SSH_CONFIG" << EOF

# Voting App Infrastructure - Added $(date)
Host frontend-instance
  HostName $FRONTEND_PUBLIC_IP
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  StrictHostKeyChecking no

Host backend-instance
  HostName $BACKEND_PRIVATE_IP
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyJump frontend-instance
  StrictHostKeyChecking no

Host db-instance
  HostName $DATABASE_PRIVATE_IP
  User ubuntu
  IdentityFile ~/.ssh/martin-ap-northeast-2-key.pem
  ProxyJump frontend-instance
  StrictHostKeyChecking no
EOF
    echo "✅ Updated SSH config"
fi

echo ""
echo "🎯 Testing Connectivity"
echo "======================="

# Test if we can reach the frontend
echo -n "Testing frontend connection... "
if ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no \
   -i ~/.ssh/martin-ap-northeast-2-key.pem ubuntu@$FRONTEND_PUBLIC_IP exit 2>/dev/null; then
    echo "✅ Success"
else
    echo "❌ Failed"
    echo "Note: This might be due to security group rules or the instance not being ready"
fi

echo ""
echo "=========================================="
echo "✅ Inventory Update Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test Ansible connectivity: ansible all -m ping"
echo "2. Install Docker: ansible-playbook playbooks/install-docker.yml"
echo "3. Deploy apps: ansible-playbook playbooks/deploy-all.yml"
echo ""
echo "Access your apps at:"
echo "  Vote:   http://$FRONTEND_PUBLIC_IP:80"
echo "  Result: http://$FRONTEND_PUBLIC_IP:5001"
echo ""
