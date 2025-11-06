# 📊 Quick Monitoring Reference Card

Your complete monitoring setup at a glance.

---

## 🔗 Access URLs

```
Grafana Dashboard (Prometheus):
http://3.36.116.222:3000/d/voting-app-demo
Login: admin / admin

Prometheus Raw Metrics:
http://3.36.116.222:9090

CloudWatch Console:
https://console.aws.amazon.com/cloudwatch/home?region=ap-northeast-2
```

---

## ⚡ Quick Commands

### **Stress Tests:**
```bash
cd ~/ironhack/project_multistack_devops_app/monitoring

# Light demo (200 votes)
./quick-stress.sh 200 20

# Heavy test (1000 votes)
./quick-stress.sh 1000 40

# Find limits (5000 votes!)
./quick-stress.sh 5000 100
```

### **Check System Status:**
```bash
# All containers
ansible all -m shell -a "docker ps"

# Monitoring stack
ansible frontend -m shell -a "docker ps | grep -E 'prometheus|grafana|node-exporter'"

# Application health
curl http://3.36.116.222:80        # Vote app
curl http://3.36.116.222:5001      # Result app
curl http://3.36.116.222:9090/-/healthy  # Prometheus
```

### **View Metrics:**
```bash
# Prometheus targets
curl http://3.36.116.222:9090/api/v1/targets | python3 -m json.tool

# Query PromQL
curl 'http://3.36.116.222:9090/api/v1/query?query=up'

# CloudWatch metrics
aws cloudwatch list-metrics \
  --namespace VotingApp/Infrastructure \
  --region ap-northeast-2
```

---

## 📊 What's Being Monitored

### **Prometheus/Grafana Stack:**
```
✅ Node Exporters (3 instances)
   - CPU, Memory, Disk, Network
   - Per-instance metrics
   - 5-second refresh rate

✅ Prometheus Server
   - Scrapes metrics every 15s
   - Stores 15 days of data
   - Port 9090

✅ Grafana Dashboards
   - Beautiful visualizations
   - Real-time updates
   - Port 3000
```

### **CloudWatch Stack:**
```
✅ EC2 Default Metrics
   - CPUUtilization
   - NetworkIn/Out
   - DiskReadOps/WriteOps

✅ CloudWatch Agent Metrics
   - Memory usage %
   - Disk usage %
   - TCP connections
   - Process counts

✅ CloudWatch Logs
   - /voting-app/system
   - /voting-app/docker
   - /voting-app/application

✅ Alarms Configured
   - High CPU (>80%)
   - High Memory (>85%)
   - Low Disk Space (>85%)
```

---

## 🎨 Dashboard Panels Explained

### **Grafana Dashboard Panels:**

1. **Architecture Header** - Shows data flow
2. **Frontend CPU** - Vote App load
3. **Backend CPU** - Worker processing
4. **Database CPU** - PostgreSQL writes
5. **Memory Usage** - RAM consumption
6. **Network Traffic** - Data flow visualization
7. **System Load** - Overall system health

### **CloudWatch Dashboard Panels:**

1. **CPU Utilization** - All 3 tiers
2. **Memory Usage** - Custom metrics
3. **Network Traffic** - Frontend activity
4. **Disk Usage** - Storage monitoring
5. **Health Checks** - Instance status
6. **Active Connections** - TCP count
7. **Recent Logs** - Live log viewer

---

## 📈 Key Metrics to Watch

### **During Stress Test:**

```
BEFORE TEST:
CPU:     1-5%
Memory:  20-30%
Network: 1-5 KB/s
Load:    0.0-0.5

DURING TEST:
CPU:     40-80% ⚡
Memory:  30-50%
Network: 100-200 KB/s ⚡
Load:    2.0-4.0 ⚡

AFTER TEST:
CPU:     Gradually returns to baseline
Memory:  Stays elevated (cached data)
Network: Returns to baseline
Load:    Returns to normal
```

---

## 🚨 Alarm Thresholds

```
CPU > 80% for 10 minutes
  → VotingApp-*-HighCPU alarm

Memory > 85% for 10 minutes
  → VotingApp-*-HighMemory alarm

Disk > 85% for 5 minutes
  → VotingApp-*-LowDisk alarm
```

---

## 🎤 Presentation Checklist

### **Before Demo:**
- [ ] Open Grafana dashboard
- [ ] Open CloudWatch console
- [ ] Open Result app (to show votes)
- [ ] Test stress script once
- [ ] Check all containers running

### **During Demo:**
1. Show architecture (Grafana header)
2. Show baseline metrics
3. Run stress test: `./quick-stress.sh 1000 40`
4. Watch metrics spike in real-time
5. Show CloudWatch for enterprise monitoring
6. Explain hybrid strategy

### **Talking Points:**
- "40+ votes per second on t3.micro instances"
- "100% data integrity under load"
- "Hybrid monitoring: Prometheus for dev, CloudWatch for production"
- "Real-time visualization with 5-second refresh"
- "All automated with Ansible and Terraform"

---

## 🔧 Troubleshooting Quick Fixes

### **Grafana not showing data:**
```bash
ssh frontend-instance "docker restart prometheus"
```

### **Metrics stopped updating:**
```bash
# Check Prometheus targets
curl http://3.36.116.222:9090/api/v1/targets

# Restart Node Exporters
ansible all -m shell -a "docker restart node-exporter"
```

### **CloudWatch no data:**
```bash
# Check agent status
ssh frontend-instance
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a query -m ec2 -c default
```

### **Containers down:**
```bash
cd ansible
ansible-playbook playbooks/deploy-all.yml
ansible-playbook playbooks/deploy-monitoring.yml
```

---

## 📊 Files Reference

```
Stress Testing:
monitoring/quick-stress.sh          - Command-line stress test
monitoring/stress-test.sh           - Interactive menu
monitoring/demo-voting-activity.sh  - Original demo script

CloudWatch:
monitoring/cloudwatch/setup-cloudwatch-complete.sh  - One-command setup
monitoring/cloudwatch/create-dashboard.sh           - Dashboard creation
monitoring/cloudwatch/CLOUDWATCH_SETUP.md          - Full guide

Ansible:
ansible/playbooks/deploy-monitoring.yml  - Deploy Prometheus/Grafana
ansible/playbooks/setup-cloudwatch.yml   - Deploy CloudWatch agent

Documentation:
PRESENTATION_GUIDE.md           - Full presentation script
STRESS_TEST_GUIDE.md           - Stress testing guide
MONITORING_COMPARISON.md       - Prometheus vs CloudWatch
PARALLEL_EXPLAINED.md          - How parallel connections work
```

---

## ⚡ Emergency Commands

### **Restart Everything:**
```bash
cd ansible

# Restart application
ansible-playbook playbooks/stop-all.yml
ansible-playbook playbooks/deploy-all.yml

# Restart monitoring
ansible-playbook playbooks/deploy-monitoring.yml
```

### **Reset Vote Counts:**
```bash
ssh db-instance "docker exec postgres psql -U postgres -d postgres -c 'TRUNCATE votes;'"
```

### **Check All Services:**
```bash
# Quick health check
for service in vote result prometheus grafana; do
  echo "Checking $service..."
  docker ps | grep $service
done
```

---

## 🎯 Success Metrics

Your infrastructure successfully handles:
- **40-50 votes/second** sustained
- **100% data integrity** under load
- **Real-time monitoring** with 5s latency
- **Automated alerting** via CloudWatch
- **Cost-effective** at ~$30/month total

---

## 📱 Contact Points

```
Vote Application:    http://3.36.116.222:80
Result Application:  http://3.36.116.222:5001
Grafana Dashboard:   http://3.36.116.222:3000
Prometheus:          http://3.36.116.222:9090
CloudWatch:          AWS Console (ap-northeast-2)
```

---

**Print this card for quick reference during your presentation!** 🎤
