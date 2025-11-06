# 🎤 Voting App Presentation Guide

Complete guide for demonstrating your multi-tier DevOps infrastructure project.

---

## 📋 Pre-Presentation Setup (5 minutes before)

### 1. Start Monitoring Stack

```bash
cd ~/ironhack/project_multistack_devops_app/monitoring
./import-dashboard.sh
```

### 2. Open Required Tabs

Open these in your browser:

**Tab 1: Vote App**
- URL: http://<FRONTEND_IP>:80
- What it shows: User voting interface

**Tab 2: Result App**
- URL: http://<FRONTEND_IP>:5001
- What it shows: Real-time vote results

**Tab 3: Grafana Dashboard**
- URL: http://<FRONTEND_IP>:3000/d/voting-app-demo
- Login: admin / admin
- What it shows: System metrics and data flow

**Tab 4: Prometheus Targets** (optional)
- URL: http://<FRONTEND_IP>:9090/targets
- What it shows: Monitoring health status

### 3. Quick Health Check

```bash
cd ~/ironhack/project_multistack_devops_app/ansible
ansible all -m shell -a "docker ps | grep -E 'vote|result|worker|redis|db'"
```

All containers should be running!

---

## 🎯 Presentation Flow (10-15 minutes)

### **Part 1: Architecture Overview** (3 min)

**What to say:**
> "I built a complete DevOps infrastructure on AWS deploying a polyglot microservices application. Let me show you the architecture..."

**Show on screen:**
- Grafana dashboard header showing the data flow
- Explain the 3-tier architecture:
  - **Frontend Tier** (Public): Vote App + Result App
  - **Backend Tier** (Private): Redis + Worker
  - **Database Tier** (Private): PostgreSQL

**Key points:**
- Multi-language stack (Python, .NET, Node.js)
- Infrastructure as Code with Terraform
- Configuration management with Ansible
- Network isolation with public/private subnets
- Bastion host security pattern

---

### **Part 2: Live Demo - Voting Flow** (4 min)

**Show Tab 1 (Vote App):**
> "This is the user-facing voting application built with Python Flask..."

1. Cast a vote manually (click Cats or Dogs)
2. Show the checkmark confirmation

**Show Tab 2 (Result App):**
> "The results are displayed in real-time from the database..."

3. Show the vote count updating

**Explain the data flow:**
```
Vote App → Redis (queue) → Worker (processes) → PostgreSQL → Result App
```

**Show Tab 3 (Grafana):**
> "Here's what's happening under the hood in our infrastructure..."

4. Point to the network traffic graph showing activity
5. Show CPU/Memory usage across all three tiers

---

### **Part 3: Infrastructure Demo** (3 min)

**Run the demo script in terminal:**
```bash
cd ~/ironhack/project_multistack_devops_app/monitoring
./demo-voting-activity.sh
```

**What to say:**
> "Let me simulate 50 users voting simultaneously to show how the system handles load..."

**Watch in Grafana (keep it visible):**
- Network traffic spike on Frontend
- Backend CPU increase (Worker processing votes)
- Memory usage across tiers
- System load indicators

**Show Tab 2 (Result App):**
- Vote counts updating rapidly

**Key points:**
- Real-time metrics collection with Prometheus
- Visualization with Grafana
- Auto-restart policies for resilience
- Resource monitoring across all tiers

---

### **Part 4: DevOps Practices** (3 min)

**Show in terminal:**

```bash
# Show Terraform structure
cd ~/ironhack/project_multistack_devops_app
tree -L 2 terraform/
```

**What to say:**
> "Everything is automated and reproducible..."

**Key technologies:**
- **Terraform**: Infrastructure as Code (VPC, subnets, security groups, EC2)
- **Ansible**: Configuration management (Docker, app deployment)
- **Docker**: Containerization (all apps run in containers)
- **AWS**: Cloud provider (3-tier architecture)
- **Monitoring**: Prometheus + Grafana + Node Exporters

**Show a quick file:**
```bash
# Show security group configuration
cat terraform/security.tf | head -30
```

**Explain:**
- Network security (security groups)
- Private subnet isolation
- Bastion host access
- Monitoring port configuration

---

### **Part 5: Q&A Prompts** (2 min)

**Anticipated questions and answers:**

**Q: "How do you handle failures?"**
> - All containers have `--restart always` policy
> - Private instances use NAT gateway for updates
> - Could add: Auto Scaling Groups, Load Balancers

**Q: "Is this production-ready?"**
> - Good for learning and staging
> - For production would add: multi-AZ, RDS, ElastiCache, ALB, secrets management

**Q: "How long did deployment take?"**
> - Initial infrastructure: ~5 minutes (Terraform)
> - Application deployment: ~3 minutes (Ansible)
> - Total automated deployment: ~8 minutes

**Q: "Can you rebuild everything?"**
```bash
# Show it's reproducible
terraform plan  # Shows what would be created
```

**Q: "How do you access private instances?"**
> - SSH bastion pattern
> - Frontend acts as jump host
> - ProxyJump configuration in SSH config

---

## 🎬 Demo Scripts Reference

### Generate Voting Activity
```bash
cd monitoring
./demo-voting-activity.sh
```

### Check Application Logs
```bash
cd ansible
ansible-playbook playbooks/check-logs.yml
```

### Show Container Status
```bash
ansible all -m shell -a "docker ps"
```

### Restart All Services
```bash
ansible-playbook playbooks/stop-all.yml
# Wait 5 seconds
ansible-playbook playbooks/deploy-all.yml
```

---

## 📊 Grafana Dashboard Explanation

**Panel Guide:**

1. **Architecture Header**: Shows data flow diagram
2. **CPU Usage (3 panels)**: Shows processing load by tier
3. **Memory Usage (3 panels)**: Shows resource consumption
4. **Network Traffic**: Shows data flowing between components
5. **System Load Gauges**: Shows overall system health

**What to highlight:**
- Frontend spikes when users vote
- Backend increases when Worker processes votes
- Database stable (just storing data)
- Network shows data transfer rates

---

## 🎯 Key Selling Points

1. **Complete DevOps Pipeline**
   - Infrastructure as Code (Terraform)
   - Configuration Management (Ansible)
   - Containerization (Docker)
   - Monitoring (Prometheus/Grafana)

2. **AWS Best Practices**
   - Multi-tier architecture
   - Network isolation
   - Security groups
   - Bastion host pattern
   - NAT gateway for private subnets

3. **Microservices Architecture**
   - Polyglot (Python, .NET, Node.js)
   - Message queue (Redis)
   - Persistent storage (PostgreSQL)
   - Container orchestration

4. **Reproducible & Documented**
   - Complete automation
   - Comprehensive documentation
   - Troubleshooting guides
   - Learning notes captured

---

## ⚠️ Troubleshooting During Demo

### Vote App Not Responding
```bash
ssh frontend-instance
docker logs vote
docker restart vote
```

### Grafana Not Showing Data
- Refresh the page (Ctrl+R)
- Check time range (last 15 minutes)
- Verify Prometheus datasource

### Network Issues
```bash
# Check all targets
curl http://<FRONTEND_IP>:9090/api/v1/targets
```

### Container Down
```bash
ansible-playbook playbooks/deploy-all.yml
```

---

## 🚀 Closing Statement

> "This project demonstrates my ability to design, implement, and monitor cloud infrastructure using industry-standard DevOps practices. The entire stack is automated, monitored, and documented - ready for team collaboration or production deployment."

**Next steps I would take:**
- Add CI/CD pipeline (GitHub Actions)
- Implement auto-scaling
- Add application-level metrics
- Set up alerting rules
- Migrate to managed services (RDS, EKS)

---

## 📸 Screenshot Checklist

Before presentation, take screenshots of:
- [ ] Architecture diagram from Grafana
- [ ] Terraform code structure
- [ ] Ansible playbook structure
- [ ] Grafana dashboard with activity
- [ ] Prometheus targets showing all UP
- [ ] AWS Console showing resources

---

**Good luck with your presentation! 🎉**

*Questions? Check `TROUBLESHOOTING_LOG.md` for common issues*
