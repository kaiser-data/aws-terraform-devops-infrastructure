# 🚀 Quick Reference Guide

**Status:** ✅ **FULLY OPERATIONAL**

---

## 🌐 Application URLs

```
Vote:    http://13.124.72.188
Results: http://13.124.72.188:5001
```

---

## 🔑 Key Information

| Item | Value |
|------|-------|
| **AWS Region** | ap-northeast-2 (Seoul) |
| **Frontend IP** | 13.124.72.188 (Public) |
| **Backend IP** | 10.0.2.139 (Private) |
| **Database IP** | 10.0.2.61 (Private) |
| **SSH Key** | ~/.ssh/martin-ap-northeast-2-key.pem |
| **Docker Hub** | kaiserdata/* |

---

## 💻 Common Commands

### Test Application
```bash
./test-voting-app.sh
```

### Check Status
```bash
# All containers
ssh frontend-instance "docker ps"
ssh backend-instance "docker ps"
ssh db-instance "docker ps"
```

### View Logs
```bash
ssh frontend-instance "docker logs vote -f"
ssh frontend-instance "docker logs result -f"
ssh backend-instance "docker logs worker -f"
```

### Restart Services
```bash
ssh frontend-instance "docker restart vote"
ssh frontend-instance "docker restart result"
ssh backend-instance "docker restart worker"
```

### Infrastructure
```bash
# Check Terraform state
cd terraform && terraform show

# Check Ansible connectivity
cd ansible && ansible all -m ping

# SSH to instances
ssh frontend-instance
ssh backend-instance
ssh db-instance
```

---

## 📁 Important Files

| File | Purpose |
|------|---------|
| `docs/INFRASTRUCTURE_STATUS.md` | Complete infrastructure documentation |
| `docs/MIGRATION_STATUS.md` | Enterprise migration progress |
| `test-voting-app.sh` | Automated testing script |
| `terraform/terraform.tfstate` | Infrastructure state |
| `ansible/inventory/hosts.yml` | Ansible inventory (auto-generated) |

---

## 🐳 Docker Images

| Image | Latest Build |
|-------|-------------|
| `kaiserdata/voting-app:latest` | Nov 5, 2025 |
| `kaiserdata/result-app:latest` | Nov 5, 2025 |
| `kaiserdata/worker-app:latest` | Nov 5, 2025 |

---

## 🔧 Troubleshooting

### Application Not Responding
```bash
# Check if containers are running
ssh frontend-instance "docker ps"

# Check logs for errors
ssh frontend-instance "docker logs vote --tail 50"

# Restart container
ssh frontend-instance "docker restart vote"
```

### Can't SSH to Private Instances
```bash
# Check SSH agent
ssh-add -l

# Add key if needed
ssh-add ~/.ssh/martin-ap-northeast-2-key.pem

# Test connection
ssh -v backend-instance
```

### No Votes Showing Up
```bash
# Check worker is processing
ssh backend-instance "docker logs worker --tail 20"

# Check Redis
ssh backend-instance "docker exec redis redis-cli LLEN votes"

# Check PostgreSQL
ssh db-instance "docker exec postgres psql -U postgres -c 'SELECT * FROM votes;'"
```

---

## 💰 Cost

**Monthly:** ~$58
- EC2 (3x t2.micro): ~$25
- NAT Gateway: ~$32
- Data Transfer: ~$1

---

## 📞 Quick Links

- [Full Documentation](docs/INFRASTRUCTURE_STATUS.md)
- [Migration Status](docs/MIGRATION_STATUS.md)
- [Application Repo](https://github.com/kaiser-data/ironhack-voting-app)

---

**Last Updated:** November 5, 2025
