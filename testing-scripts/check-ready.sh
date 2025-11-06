#!/bin/bash
# Quick readiness check

echo "🔍 Checking if you're ready to deploy..."
echo ""

READY=true

# Check Ansible
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible not installed"
    READY=false
else
    echo "✅ Ansible: $(ansible --version | head -1)"
fi

# Check Ansible Docker collection
if ansible-galaxy collection list 2>/dev/null | grep -q community.docker; then
    echo "✅ Ansible Docker collection installed"
else
    echo "❌ Missing: ansible-galaxy collection install community.docker"
    READY=false
fi

# Check Python docker module
if python3 -c "import docker" 2>/dev/null; then
    echo "✅ Python Docker SDK installed"
else
    echo "❌ Missing: pip3 install docker"
    READY=false
fi

# Check Terraform
if [ -f "terraform/terraform.tfvars" ]; then
    echo "✅ terraform.tfvars exists"
else
    echo "❌ Missing: terraform/terraform.tfvars"
    READY=false
fi

# Check SSH key
if [ -f ~/.ssh/martin-ap-northeast-2-key.pem ]; then
    echo "✅ SSH key exists"
else
    echo "❌ SSH key not found at ~/.ssh/martin-ap-northeast-2-key.pem"
    READY=false
fi

# Check Docker Hub username
if grep -q "your-dockerhub-username" ansible/group_vars/all.yml 2>/dev/null; then
    echo "⚠️  Update Docker Hub username in ansible/group_vars/all.yml"
    READY=false
else
    echo "✅ Docker Hub username configured"
fi

echo ""
if [ "$READY" = true ]; then
    echo "🎉 You're ready to deploy!"
    echo ""
    echo "Next steps:"
    echo "  cd terraform/ && terraform apply"
    echo "  cd ../ansible/ && ansible all -m ping"
else
    echo "❌ Please fix the issues above before deploying"
    echo ""
    echo "Quick fixes:"
    echo "  ansible-galaxy collection install community.docker"
    echo "  pip3 install docker"
fi
