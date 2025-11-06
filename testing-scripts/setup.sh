#!/bin/bash
# Project Setup Script - Creates config files from examples

set -e

echo "=========================================="
echo "🚀 Voting App Project Setup"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to prompt for input with default
prompt_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        input="${input:-$default}"
    else
        read -p "$prompt: " input
    fi

    eval "$var_name='$input'"
}

# Check if .env already exists
if [ -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file already exists${NC}"
    read -p "Do you want to overwrite it? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
        echo "Skipping .env creation"
        SKIP_ENV=true
    fi
fi

# Create .env file
if [ "$SKIP_ENV" != "true" ]; then
    echo -e "${BLUE}📝 Setting up environment variables${NC}"
    echo ""

    # Get current IP
    CURRENT_IP=$(curl -s ifconfig.me 2>/dev/null || echo "")

    prompt_input "AWS Region" "ap-northeast-2" AWS_REGION
    prompt_input "AWS Key Pair Name" "YOUR_KEY_NAME" KEY_PAIR_NAME
    prompt_input "Your Public IP" "$CURRENT_IP" MY_IP
    prompt_input "Docker Hub Username" "" DOCKERHUB_USERNAME
    prompt_input "PostgreSQL Password" "postgres" POSTGRES_PASSWORD

    # Create .env file
    cat > .env << EOF
# Environment Variables for Voting App Deployment
# Generated: $(date)

# AWS Configuration
export AWS_REGION="$AWS_REGION"
export AWS_PROFILE="default"

# Terraform Variables
export TF_VAR_aws_region="$AWS_REGION"
export TF_VAR_key_pair_name="$KEY_PAIR_NAME"
export TF_VAR_my_ip="$MY_IP/32"

# Docker Hub Configuration
export DOCKERHUB_USERNAME="$DOCKERHUB_USERNAME"

# Database Credentials
export POSTGRES_USER="postgres"
export POSTGRES_PASSWORD="$POSTGRES_PASSWORD"
export POSTGRES_DB="postgres"

# SSH Configuration
export SSH_KEY_PATH="~/.ssh/${KEY_PAIR_NAME}.pem"

# Ansible Configuration
export ANSIBLE_HOST_KEY_CHECKING="False"
export ANSIBLE_STDOUT_CALLBACK="yaml"
EOF

    echo -e "${GREEN}✅ Created .env file${NC}"
    echo ""
fi

# Create terraform.tfvars
if [ -f terraform/terraform.tfvars ]; then
    echo -e "${YELLOW}⚠️  terraform/terraform.tfvars already exists${NC}"
    read -p "Do you want to overwrite it? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
        echo "Skipping terraform.tfvars creation"
        SKIP_TF=true
    fi
fi

if [ "$SKIP_TF" != "true" ]; then
    # Source .env if it exists
    if [ -f .env ]; then
        source .env
    fi

    cat > terraform/terraform.tfvars << EOF
# Terraform Variables
# Generated: $(date)

aws_region    = "${TF_VAR_aws_region:-ap-northeast-2}"
key_pair_name = "${TF_VAR_key_pair_name:-YOUR_KEY_NAME}"
my_ip         = "${TF_VAR_my_ip:-YOUR_IP/32}"
EOF

    echo -e "${GREEN}✅ Created terraform/terraform.tfvars${NC}"
    echo ""
fi

# Create ansible/group_vars/all.yml
if [ -f ansible/group_vars/all.yml ]; then
    echo -e "${YELLOW}⚠️  ansible/group_vars/all.yml already exists${NC}"
    read -p "Do you want to overwrite it? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
        echo "Skipping all.yml creation"
        SKIP_ANSIBLE=true
    fi
fi

if [ "$SKIP_ANSIBLE" != "true" ]; then
    # Source .env if it exists
    if [ -f .env ]; then
        source .env
    fi

    cat > ansible/group_vars/all.yml << EOF
---
# Global variables for all hosts
# Generated: $(date)

# Docker Hub username
dockerhub_username: "${DOCKERHUB_USERNAME:-YOUR_DOCKERHUB_USERNAME}"

# Image versions
vote_image_tag: "latest"
result_image_tag: "latest"
worker_image_tag: "latest"
redis_image_tag: "alpine"
postgres_image_tag: "15-alpine"

# Database credentials
postgres_user: "${POSTGRES_USER:-postgres}"
postgres_password: "${POSTGRES_PASSWORD:-postgres}"
postgres_db: "${POSTGRES_DB:-postgres}"

# Application ports
vote_port: 80
result_port: 80
redis_port: 6379
postgres_port: 5432
EOF

    echo -e "${GREEN}✅ Created ansible/group_vars/all.yml${NC}"
    echo ""
fi

# Summary
echo "=========================================="
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Files created:"
if [ "$SKIP_ENV" != "true" ]; then
    echo "  ✅ .env"
fi
if [ "$SKIP_TF" != "true" ]; then
    echo "  ✅ terraform/terraform.tfvars"
fi
if [ "$SKIP_ANSIBLE" != "true" ]; then
    echo "  ✅ ansible/group_vars/all.yml"
fi
echo ""

echo -e "${BLUE}Next steps:${NC}"
echo ""
echo "1. Load environment variables:"
echo "   source .env"
echo ""
echo "2. Verify SSH key exists:"
echo "   ls -la ~/.ssh/${KEY_PAIR_NAME:-YOUR_KEY}.pem"
echo ""
echo "3. Install prerequisites:"
echo "   pip3 install docker"
echo "   ansible-galaxy collection install community.docker"
echo ""
echo "4. Deploy infrastructure:"
echo "   cd terraform/"
echo "   terraform init"
echo "   terraform apply"
echo ""
echo "5. Deploy applications:"
echo "   cd ../ansible/"
echo "   ansible all -m ping"
echo "   ansible-playbook playbooks/install-docker.yml"
echo "   ansible-playbook playbooks/deploy-all.yml"
echo ""
echo "=========================================="
echo -e "${GREEN}Happy deploying! 🚀${NC}"
echo "=========================================="
