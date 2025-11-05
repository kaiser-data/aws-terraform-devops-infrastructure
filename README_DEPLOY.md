# 🎯 Quick Deploy - TL;DR Version

For experienced users who just want to deploy quickly.

## Prerequisites

```bash
# Install tools
pip3 install docker
ansible-galaxy collection install community.docker
```

## Deploy (5 Commands)

```bash
# 1. Setup configuration
./setup.sh

# 2. Load environment
source .env

# 3. Deploy infrastructure
cd terraform/ && terraform init && terraform apply

# 4. Setup SSH and deploy apps
cat ../ansible/ssh_config >> ~/.ssh/config
cd ../ansible/
ansible all -m ping
ansible-playbook playbooks/install-docker.yml
ansible-playbook playbooks/deploy-all.yml

# 5. Get URLs
cd ../terraform/
terraform output ansible_setup_complete
```

## Access

```bash
FRONTEND_IP=$(cd terraform && terraform output -raw frontend_public_ip)
echo "Vote:   http://$FRONTEND_IP:80"
echo "Result: http://$FRONTEND_IP:5001"
```

## Configuration Files

| File | Purpose | Git Status |
|------|---------|------------|
| `.env` | Your settings | Ignored |
| `terraform/terraform.tfvars` | Terraform vars | Ignored |
| `ansible/group_vars/all.yml` | Ansible vars | Ignored |
| `*.example` | Templates | Committed |

## One-Liner Deploy

```bash
./setup.sh && source .env && cd terraform && terraform init && terraform apply -auto-approve && cat ../ansible/ssh_config >> ~/.ssh/config && cd ../ansible && ansible all -m ping && ansible-playbook playbooks/install-docker.yml && ansible-playbook playbooks/deploy-all.yml
```

**Done!** 🎉

Full docs: [SETUP_GUIDE.md](SETUP_GUIDE.md)
