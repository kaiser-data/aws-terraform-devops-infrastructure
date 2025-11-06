# ☁️ AWS CloudWatch Setup Guide

Complete guide to setting up AWS CloudWatch monitoring for your Voting App infrastructure.

---

## 🎯 What CloudWatch Adds

**CloudWatch complements Prometheus/Grafana with:**
- ✅ **Native AWS integration** - Built-in EC2 metrics
- ✅ **Managed service** - No infrastructure to maintain
- ✅ **Alarms & notifications** - Automated alerting
- ✅ **Log aggregation** - Centralized log management
- ✅ **Long-term retention** - Historical data storage
- ✅ **AWS Console integration** - Familiar interface

---

## 📋 Prerequisites

### **1. IAM Permissions**

Your AWS account needs these permissions:
- `cloudwatch:PutMetricData`
- `logs:CreateLogGroup`
- `logs:CreateLogStream`
- `logs:PutLogEvents`
- `ec2:DescribeInstances`

### **2. AWS CLI Configured**

```bash
# Check if AWS CLI is configured
aws sts get-caller-identity

# If not configured, run:
aws configure
```

---

## 🚀 Quick Setup (5 Steps)

### **Step 1: Apply Terraform Changes**

```bash
cd ~/ironhack/project_multistack_devops_app/terraform

# Review changes
terraform plan | grep cloudwatch

# Apply CloudWatch IAM roles and alarms
terraform apply -auto-approve
```

**What this creates:**
- ✅ IAM role for CloudWatch agent
- ✅ Instance profile for EC2 instances
- ✅ CloudWatch alarms (CPU, Memory, Disk)
- ✅ Log groups

### **Step 2: Attach IAM Role to Instances**

```bash
# Get instance profile name
PROFILE_NAME=$(terraform output -raw cloudwatch_instance_profile)

# Attach to frontend instance
FRONTEND_ID=$(terraform output -raw frontend_instance_id)
aws ec2 associate-iam-instance-profile \
    --instance-id ${FRONTEND_ID} \
    --iam-instance-profile Name=${PROFILE_NAME} \
    --region ap-northeast-2

# Attach to backend instance
BACKEND_ID=$(terraform output -raw backend_instance_id)
aws ec2 associate-iam-instance-profile \
    --instance-id ${BACKEND_ID} \
    --iam-instance-profile Name=${PROFILE_NAME} \
    --region ap-northeast-2

# Attach to database instance
DATABASE_ID=$(terraform output -raw database_instance_id)
aws ec2 associate-iam-instance-profile \
    --instance-id ${DATABASE_ID} \
    --iam-instance-profile Name=${PROFILE_NAME} \
    --region ap-northeast-2
```

### **Step 3: Deploy CloudWatch Agent**

```bash
cd ~/ironhack/project_multistack_devops_app/ansible

# Install and configure CloudWatch agent on all instances
ansible-playbook playbooks/setup-cloudwatch.yml
```

**This will:**
- Download CloudWatch agent
- Install on all 3 instances
- Configure metrics collection
- Start the agent
- Begin sending metrics to CloudWatch

### **Step 4: Create CloudWatch Dashboard**

```bash
cd ~/ironhack/project_multistack_devops_app/monitoring/cloudwatch

# Create dashboard
./create-dashboard.sh
```

### **Step 5: View in AWS Console**

Open the CloudWatch dashboard:
```
https://console.aws.amazon.com/cloudwatch/home?region=ap-northeast-2
```

---

## 📊 What Gets Monitored

### **Default EC2 Metrics** (Free)
- CPU Utilization
- Network In/Out
- Disk Read/Write Operations
- Status Checks

### **Custom Metrics** (via CloudWatch Agent)
- ✅ Memory Usage (%)
- ✅ Disk Usage (%)
- ✅ Per-CPU metrics
- ✅ Disk I/O statistics
- ✅ Network statistics
- ✅ TCP connections
- ✅ Process counts

### **Logs Collected**
- `/var/log/syslog` → CloudWatch Logs
- `/var/log/docker.log` → CloudWatch Logs
- Docker container logs → CloudWatch Logs

---

## 🚨 Alarms Configured

### **1. High CPU Alarm**
```
Metric: CPUUtilization
Threshold: > 80%
Duration: 2 periods (10 minutes)
Action: (Configure SNS for notifications)
```

**Triggers when:**
- Frontend, Backend, or Database CPU exceeds 80%
- Sustained for 10 minutes

### **2. High Memory Alarm**
```
Metric: MEMORY_USED
Threshold: > 85%
Duration: 2 periods (10 minutes)
```

**Triggers when:**
- Memory usage exceeds 85%

### **3. Low Disk Space Alarm**
```
Metric: DISK_USED
Threshold: > 85%
Duration: 1 period (5 minutes)
```

**Triggers when:**
- Disk usage exceeds 85%

---

## 📈 Viewing Metrics

### **Method 1: CloudWatch Console**

1. Go to: https://console.aws.amazon.com/cloudwatch/
2. Click **Dashboards** → **VotingApp-Infrastructure**
3. View all metrics in one place

### **Method 2: Metrics Explorer**

1. Click **Metrics** → **All metrics**
2. Select namespace:
   - `AWS/EC2` - Default EC2 metrics
   - `VotingApp/Infrastructure` - Custom metrics

### **Method 3: AWS CLI**

```bash
# Get CPU utilization for last hour
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=<instance-id> \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average \
    --region ap-northeast-2
```

---

## 📝 Viewing Logs

### **Log Groups:**
```
/voting-app/system       - System logs (syslog)
/voting-app/docker       - Docker daemon logs
/voting-app/application  - Application logs
```

### **View Logs in Console:**

1. Go to CloudWatch → **Logs** → **Log groups**
2. Click on `/voting-app/system`
3. Select a log stream (instance ID)
4. View real-time logs

### **Query Logs with Insights:**

```sql
-- Find errors in last hour
fields @timestamp, @message
| filter @message like /error/i
| sort @timestamp desc
| limit 20

-- Count log entries by instance
fields @timestamp
| stats count() by @logStream
| sort count() desc

-- Find Docker container issues
fields @timestamp, @message
| filter @message like /container/
| sort @timestamp desc
```

---

## 🎨 CloudWatch Dashboard Features

### **Widgets Created:**

1. **Architecture Header** - Shows 3-tier structure
2. **CPU Utilization** - All 3 tiers in one graph
3. **Memory Usage** - Custom metric tracking
4. **Network Traffic** - Frontend network activity
5. **Disk Usage** - Storage monitoring
6. **Health Checks** - Instance status
7. **Active Connections** - TCP connection count
8. **Recent Logs** - Live log viewer

### **Customizing Dashboard:**

```bash
# Edit the dashboard
aws cloudwatch get-dashboard \
    --dashboard-name VotingApp-Infrastructure \
    --region ap-northeast-2 > dashboard.json

# Edit dashboard.json as needed

# Update dashboard
aws cloudwatch put-dashboard \
    --dashboard-name VotingApp-Infrastructure \
    --dashboard-body file://dashboard.json \
    --region ap-northeast-2
```

---

## 🔔 Setting Up Alarm Notifications

### **Step 1: Create SNS Topic**

```bash
# Create SNS topic for alarms
aws sns create-topic \
    --name VotingApp-Alarms \
    --region ap-northeast-2

# Subscribe your email
aws sns subscribe \
    --topic-arn arn:aws:sns:ap-northeast-2:ACCOUNT_ID:VotingApp-Alarms \
    --protocol email \
    --notification-endpoint your-email@example.com \
    --region ap-northeast-2

# Confirm subscription in email
```

### **Step 2: Update Alarms**

```bash
# Update alarm to send notifications
aws cloudwatch put-metric-alarm \
    --alarm-name VotingApp-Frontend-HighCPU \
    --alarm-actions arn:aws:sns:ap-northeast-2:ACCOUNT_ID:VotingApp-Alarms \
    --region ap-northeast-2 \
    ... (other parameters)
```

---

## 💰 Cost Estimation

### **CloudWatch Pricing (ap-northeast-2):**

```
Metrics:
- First 10 custom metrics: FREE
- Additional metrics: $0.30/metric/month

Logs:
- Ingestion: $0.76/GB
- Storage: $0.033/GB/month
- Insights queries: $0.0076/GB scanned

Alarms:
- Standard metrics: $0.10/alarm/month
- High-resolution: $0.30/alarm/month

Dashboards:
- First 3 dashboards: FREE
- Additional: $3/dashboard/month
```

### **Your Estimated Cost:**
```
Metrics: ~20 custom metrics = $3/month
Logs: ~1GB/month = $1/month
Alarms: 6 alarms = $0.60/month
Dashboard: 1 dashboard = FREE

Total: ~$5/month
```

---

## 🎤 Presentation Tips

### **Demo Flow:**

1. **Show Prometheus/Grafana**
   > "Here's our open-source monitoring stack..."

2. **Switch to CloudWatch**
   > "We also integrate with AWS CloudWatch for cloud-native monitoring..."

3. **Show Dashboard**
   > "This gives us AWS-native metrics, alarms, and log aggregation..."

4. **Trigger Alarm**
   ```bash
   # Run stress test to trigger CPU alarm
   cd monitoring
   ./quick-stress.sh 2000 50
   ```
   > "Watch as the alarm triggers when CPU exceeds 80%..."

5. **Show Logs**
   > "All logs are centralized in CloudWatch Logs for easy troubleshooting..."

### **Key Talking Points:**

- **Hybrid Monitoring**: "We use both Prometheus for detailed metrics and CloudWatch for AWS integration"
- **Cost-Effective**: "Only ~$5/month for enterprise-grade monitoring"
- **Automated Alerts**: "Alarms automatically notify us of issues"
- **Compliance**: "CloudWatch provides audit logs and long-term retention"

---

## 🔧 Troubleshooting

### **Agent Not Sending Metrics?**

```bash
# Check agent status
ssh frontend-instance
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a query -m ec2 -c default

# Check agent logs
sudo cat /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Restart agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a stop -m ec2
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
```

### **IAM Permissions Issues?**

```bash
# Check if instance has IAM role
aws ec2 describe-instances \
    --instance-ids <instance-id> \
    --query 'Reservations[0].Instances[0].IamInstanceProfile' \
    --region ap-northeast-2

# Verify role permissions
aws iam get-role \
    --role-name VotingApp-CloudWatchAgentRole
```

### **Metrics Not Appearing?**

- Wait 5-10 minutes for first metrics to appear
- Check namespace is correct: `VotingApp/Infrastructure`
- Verify agent is running
- Check IAM role is attached to instance

---

## 📚 Additional Resources

- [CloudWatch Agent Config Reference](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)
- [CloudWatch Logs Insights Query Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
- [CloudWatch Pricing](https://aws.amazon.com/cloudwatch/pricing/)

---

## ✅ Setup Checklist

- [ ] Terraform applied (IAM roles created)
- [ ] Instance profiles attached to EC2 instances
- [ ] CloudWatch agent installed on all instances
- [ ] Metrics appearing in CloudWatch console
- [ ] Dashboard created and accessible
- [ ] Alarms configured
- [ ] Log groups receiving logs
- [ ] SNS topic for notifications (optional)
- [ ] Test alarm by triggering threshold

---

**CloudWatch Setup Complete!** ☁️

*Now you have both open-source (Prometheus/Grafana) and cloud-native (CloudWatch) monitoring!*
