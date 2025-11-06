# Monitoring Architecture - Grafana & CloudWatch Explained

Complete explanation of how Grafana and CloudWatch collect, store, and display metrics.

---

## 🎯 Two Monitoring Systems

This project uses **dual monitoring** for different purposes:

| System | Purpose | Data Flow | Cost |
|--------|---------|-----------|------|
| **Prometheus + Grafana** | Real-time debugging, development | Pull (scraping) | Free |
| **CloudWatch** | Production monitoring, alerts | Push (agent) | ~$7/month |

---

# 📊 Grafana Architecture (Pull Model)

## Complete Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  EC2 Instances (Data Sources)                                   │
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │  Frontend        │  │  Backend         │  │  Database    │ │
│  │  10.0.1.22       │  │  <BACKEND_IP>       │  │  <DB_IP>  │ │
│  │                  │  │                  │  │              │ │
│  │  Node Exporter   │  │  Node Exporter   │  │ Node Exporter│ │
│  │  :9100           │  │  :9100           │  │ :9100        │ │
│  │  ↓               │  │  ↓               │  │ ↓            │ │
│  │  [Metrics]       │  │  [Metrics]       │  │ [Metrics]    │ │
│  │  • CPU usage     │  │  • CPU usage     │  │ • CPU usage  │ │
│  │  • Memory        │  │  • Memory        │  │ • Memory     │ │
│  │  • Disk          │  │  • Disk          │  │ • Disk       │ │
│  │  • Network       │  │  • Network       │  │ • Network    │ │
│  └────────┬─────────┘  └─────────┬────────┘  └──────┬───────┘ │
│           │                      │                    │         │
│           │  Redis Exporter      │  Postgres Exporter│         │
│           │  :9121               │  :9187            │         │
│           │  ↓                   │  ↓                │         │
│           │  [App Metrics]       │  [DB Metrics]     │         │
│           │  • Queue length      │  • Vote count     │         │
│           │  • Commands/sec      │  • Connections    │         │
└───────────┼──────────────────────┼───────────────────┼─────────┘
            │                      │                   │
            │   ◄──── SCRAPING (Pull every 15s) ──────┤
            │                      │                   │
            ▼                      ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│  Prometheus (Frontend - 10.0.1.22:9090)                         │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Scraper Engine                                            │ │
│  │  • Reads prometheus.yml config                             │ │
│  │  • Every 15 seconds, pulls from all targets               │ │
│  │  • Stores time-series data in local database              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Time-Series Database (TSDB)                               │ │
│  │  • Stores metrics with timestamps                          │ │
│  │  • Retention: 15 days (default)                            │ │
│  │  • Format: metric{labels} value timestamp                  │ │
│  │  • Example: cpu_usage{instance="frontend"} 45.2 1699285200│ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  PromQL Query Engine                                       │ │
│  │  • Processes queries from Grafana                          │ │
│  │  • Aggregations, calculations, functions                   │ │
│  │  • Returns time-series data                                │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────┬────────────────────────────────┘
                                   │
                   HTTP API :9090  │  (Grafana queries this)
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│  Grafana (Frontend - 10.0.1.22:3000)                            │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Data Source Configuration                                 │ │
│  │  • Prometheus URL: http://localhost:9090                   │ │
│  │  • Queries Prometheus API                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Dashboard Engine                                          │ │
│  │  • Sends PromQL queries to Prometheus                      │ │
│  │  • Receives time-series data                               │ │
│  │  • Renders graphs, gauges, tables                          │ │
│  │  • Auto-refreshes (default: 5s)                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Web UI :3000                                              │ │
│  │  • You access: http://<FRONTEND_IP>:3000                   │ │
│  │  • Shows: Voting Application Architecture dashboard       │ │
│  │  • Real-time graphs of CPU, Memory, Network               │ │
│  └────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

---

## How Grafana Gets Data (Step-by-Step)

### Step 1: Exporters Expose Metrics

**Node Exporter runs on each instance:**

```bash
# On Frontend (10.0.1.22:9100):
docker run -d \
  --name node-exporter \
  --net="host" \
  prom/node-exporter:latest

# Exposes metrics at: http://10.0.1.22:9100/metrics
```

**What metrics look like:**

```
# HELP node_cpu_seconds_total Seconds the CPUs spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} 1234567.89
node_cpu_seconds_total{cpu="0",mode="system"} 12345.67
node_cpu_seconds_total{cpu="0",mode="user"} 23456.78

# HELP node_memory_MemTotal_bytes Memory information field MemTotal_bytes.
# TYPE node_memory_MemTotal_bytes gauge
node_memory_MemTotal_bytes 1.073741824e+09

# HELP node_memory_MemAvailable_bytes Memory information field MemAvailable_bytes.
# TYPE node_memory_MemAvailable_bytes gauge
node_memory_MemAvailable_bytes 5.36870912e+08
```

**Format:** Plain text with metric name, labels, and value.

---

### Step 2: Prometheus Configuration

**File:** `monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s        # Pull metrics every 15 seconds

scrape_configs:
  # Frontend Node Exporter
  - job_name: 'frontend-node'
    static_configs:
      - targets: ['localhost:9100']    # Frontend scrapes itself
        labels:
          instance: 'frontend'

  # Backend Node Exporter (via private IP)
  - job_name: 'backend-node'
    static_configs:
      - targets: ['<BACKEND_IP>:9100']    # Prometheus reaches backend
        labels:
          instance: 'backend'

  # Database Node Exporter (via private IP)
  - job_name: 'database-node'
    static_configs:
      - targets: ['<DB_IP>:9100']   # Prometheus reaches database
        labels:
          instance: 'database'

  # Redis Exporter (application metrics)
  - job_name: 'redis'
    static_configs:
      - targets: ['<BACKEND_IP>:9121']

  # Postgres Exporter (application metrics)
  - job_name: 'postgres'
    static_configs:
      - targets: ['<DB_IP>:9187']
```

---

### Step 3: Prometheus Scrapes Targets

**Every 15 seconds, Prometheus:**

1. **Sends HTTP GET request** to each target:
   ```
   GET http://10.0.1.22:9100/metrics
   GET http://<BACKEND_IP>:9100/metrics
   GET http://<DB_IP>:9100/metrics
   GET http://<BACKEND_IP>:9121/metrics
   GET http://<DB_IP>:9187/metrics
   ```

2. **Receives metrics** as plain text

3. **Parses metrics** and adds timestamps

4. **Stores in TSDB** (Time-Series Database):
   ```
   node_cpu_seconds_total{instance="frontend",cpu="0",mode="user"} 23456.78 @1699285200
   node_cpu_seconds_total{instance="backend",cpu="0",mode="user"} 12345.67 @1699285200
   ```

5. **Repeats** every 15 seconds

**Key Point:** This is a **PULL model** - Prometheus actively fetches data.

---

### Step 4: Grafana Queries Prometheus

**When you open Grafana dashboard:**

1. **Grafana connects to Prometheus:**
   ```
   Data Source: http://localhost:9090
   ```

2. **Grafana sends PromQL queries:**
   ```promql
   # CPU usage query:
   100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

   # Memory usage query:
   (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

   # Network traffic query:
   rate(node_network_receive_bytes_total[5m])
   ```

3. **Prometheus calculates** the result from stored metrics

4. **Returns time-series data** to Grafana:
   ```json
   {
     "status": "success",
     "data": {
       "result": [
         {
           "metric": {"instance": "frontend"},
           "values": [[1699285200, "45.2"], [1699285215, "47.8"], ...]
         }
       ]
     }
   }
   ```

5. **Grafana renders** the graph in real-time

---

### Step 5: Auto-Refresh

**Grafana dashboard refreshes every 5 seconds:**

```
Every 5 seconds:
  ↓
Grafana → PromQL query → Prometheus
       ← Time-series data ←
  ↓
Update graphs
```

**Result:** You see **real-time metrics** updated continuously!

---

## Why This Architecture?

### Advantages of Pull Model (Prometheus):

1. **Service Discovery:** Prometheus knows if a target is down (scrape fails)
2. **Centralized Config:** All targets defined in `prometheus.yml`
3. **No Firewall Issues:** Prometheus initiates connections
4. **Historical Data:** Stored locally for 15 days

### Grafana Benefits:

1. **Beautiful Visualizations:** Better than Prometheus UI
2. **Multiple Data Sources:** Can combine Prometheus, CloudWatch, etc.
3. **Alerting:** Can trigger alerts based on metrics
4. **Dashboards:** Shareable, customizable

---

# ☁️ CloudWatch Architecture (Push Model)

## Complete Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  EC2 Instances (Data Sources)                                   │
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │  Frontend        │  │  Backend         │  │  Database    │ │
│  │  10.0.1.22       │  │  <BACKEND_IP>       │  │  <DB_IP>  │ │
│  │                  │  │                  │  │              │ │
│  │  ┌────────────┐  │  │  ┌────────────┐  │  │ ┌──────────┐│ │
│  │  │ CW Agent   │  │  │  │ CW Agent   │  │  │ │ CW Agent ││ │
│  │  │            │  │  │  │            │  │  │ │          ││ │
│  │  │ Collects:  │  │  │  │ Collects:  │  │  │ │ Collects:││ │
│  │  │ • CPU      │  │  │  │ • CPU      │  │  │ │ • CPU    ││ │
│  │  │ • Memory   │  │  │  │ • Memory   │  │  │ │ • Memory ││ │
│  │  │ • Disk     │  │  │  │ • Disk     │  │  │ │ • Disk   ││ │
│  │  │ • Network  │  │  │  │ • Network  │  │  │ │ • Network││ │
│  │  └─────┬──────┘  │  │  └─────┬──────┘  │  │ └────┬─────┘│ │
│  │        │         │  │        │         │  │      │      │ │
│  │        │ IAM     │  │        │ IAM     │  │      │ IAM  │ │
│  │        │ Role    │  │        │ Role    │  │      │ Role │ │
│  └────────┼─────────┘  └────────┼─────────┘  └──────┼──────┘ │
│           │                     │                    │        │
│           │   ◄──── PUSH (every 60s) ────►          │        │
│           │                     │                    │        │
└───────────┼─────────────────────┼────────────────────┼────────┘
            │                     │                    │
            │   HTTPS :443        │                    │
            │   (Egress only)     │                    │
            ▼                     ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  AWS CloudWatch (Managed Service - ap-northeast-2)              │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Metrics Storage                                           │ │
│  │  • Namespace: VotingApp/Infrastructure                     │ │
│  │  • Metrics organized by:                                   │ │
│  │    - Metric name (CPU_USAGE, MEMORY_USED, etc.)           │ │
│  │    - Dimensions (host=ip-10-0-1-22, instance=frontend)    │ │
│  │  • Retention: 15 months                                    │ │
│  │  • Stored in AWS-managed database                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  CloudWatch Alarms                                         │ │
│  │                                                             │ │
│  │  1. High CPU Alarm                                         │ │
│  │     • Metric: CPU_USAGE                                    │ │
│  │     • Threshold: > 80%                                     │ │
│  │     • Period: 5 minutes                                    │ │
│  │     • Action: Send SNS notification                        │ │
│  │                                                             │ │
│  │  2. High Memory Alarm                                      │ │
│  │     • Metric: MEMORY_USED                                  │ │
│  │     • Threshold: > 80%                                     │ │
│  │     • Period: 5 minutes                                    │ │
│  │     • Action: Send SNS notification                        │ │
│  │                                                             │ │
│  │  3. Low Disk Space Alarm                                   │ │
│  │     • Metric: DISK_USED                                    │ │
│  │     • Threshold: > 80%                                     │ │
│  │     • Period: 5 minutes                                    │ │
│  │     • Action: Send SNS notification                        │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  SNS Topic: VotingApp-Alerts                               │ │
│  │  • Subscription: martinkaiser.bln@gmail.com                │ │
│  │  • Protocol: Email                                         │ │
│  └───────────────────────────────┬────────────────────────────┘ │
└────────────────────────────────┬─┴────────────────────────────────┘
                                 │
                    Email via SNS │
                                 │
                                 ▼
                    ┌──────────────────────────┐
                    │  Your Email              │
                    │  martinkaiser.bln@gmail  │
                    │                          │
                    │  Subject: ALARM          │
                    │  "CPU usage > 80%"       │
                    └──────────────────────────┘
```

---

## How CloudWatch Works (Step-by-Step)

### Step 1: IAM Role Setup

**Terraform creates IAM role:**

```hcl
# terraform/cloudwatch.tf
resource "aws_iam_role" "cloudwatch_agent" {
  name = "VotingApp-CloudWatchAgentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach AWS managed policy for CloudWatch
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create instance profile
resource "aws_iam_instance_profile" "cloudwatch_agent" {
  name = "VotingApp-CloudWatchProfile"
  role = aws_iam_role.cloudwatch_agent.name
}

# Attach to EC2 instances
resource "aws_instance" "frontend" {
  # ... other config ...
  iam_instance_profile = aws_iam_instance_profile.cloudwatch_agent.name
}
```

**What this does:**
- Gives EC2 instances permission to **push metrics** to CloudWatch
- No API keys needed - uses instance metadata service
- Secure - credentials never exposed

---

### Step 2: CloudWatch Agent Installation

**Ansible installs agent:**

```yaml
# ansible/playbooks/setup-cloudwatch.yml
- name: Download CloudWatch agent
  ansible.builtin.get_url:
    url: https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    dest: /tmp/amazon-cloudwatch-agent.deb

- name: Install CloudWatch agent
  ansible.builtin.apt:
    deb: /tmp/amazon-cloudwatch-agent.deb
    state: present

- name: Copy CloudWatch configuration
  ansible.builtin.copy:
    src: ../cloudwatch-config.json
    dest: /opt/aws/amazon-cloudwatch-agent/etc/config.json

- name: Start CloudWatch agent
  ansible.builtin.command:
    cmd: >
      /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl
      -a fetch-config
      -m ec2
      -s
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
```

---

### Step 3: Agent Configuration

**File:** `monitoring/cloudwatch/cloudwatch-config.json`

```json
{
  "agent": {
    "metrics_collection_interval": 60,
    "region": "ap-northeast-2"
  },
  "metrics": {
    "namespace": "VotingApp/Infrastructure",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          },
          {
            "name": "cpu_usage_system",
            "rename": "CPU_SYSTEM",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEMORY_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
```

**Configuration explained:**
- `metrics_collection_interval: 60` → Collect every 60 seconds
- `namespace: "VotingApp/Infrastructure"` → Groups your metrics
- `rename:` → Custom metric names
- `resources: ["/"]` → Monitor root disk

---

### Step 4: Agent Pushes Metrics

**Every 60 seconds, CloudWatch agent:**

1. **Collects system metrics:**
   ```bash
   # Agent reads system files:
   /proc/stat        # CPU usage
   /proc/meminfo     # Memory usage
   /proc/diskstats   # Disk I/O
   /proc/net/dev     # Network traffic
   ```

2. **Calculates values:**
   ```
   CPU Usage: (total - idle) / total * 100
   Memory Used: (total - available) / total * 100
   Disk Used: used / total * 100
   ```

3. **Formats as CloudWatch API call:**
   ```json
   {
     "Namespace": "VotingApp/Infrastructure",
     "MetricData": [
       {
         "MetricName": "CPU_USAGE",
         "Dimensions": [
           {"Name": "host", "Value": "ip-10-0-1-22"},
           {"Name": "instance", "Value": "frontend"}
         ],
         "Value": 45.2,
         "Unit": "Percent",
         "Timestamp": "2025-11-06T14:00:00Z"
       }
     ]
   }
   ```

4. **Sends HTTPS POST** to CloudWatch API:
   ```
   POST https://monitoring.ap-northeast-2.amazonaws.com/
   Authorization: AWS4-HMAC-SHA256 ...
   ```

5. **Uses IAM role credentials** from instance metadata

**Key Point:** This is a **PUSH model** - Agent sends data to CloudWatch.

---

### Step 5: CloudWatch Stores Metrics

**CloudWatch receives metrics and:**

1. **Stores in managed database** (you don't see this)
2. **Indexes by:**
   - Namespace (`VotingApp/Infrastructure`)
   - Metric name (`CPU_USAGE`)
   - Dimensions (`host`, `instance`)
   - Timestamp

3. **Retains for 15 months** automatically

---

### Step 6: CloudWatch Alarms Evaluate

**Every 5 minutes, CloudWatch:**

1. **Checks alarm conditions:**
   ```
   Alarm: HighCPU-Frontend
   Condition: CPU_USAGE > 80% for 2 consecutive periods
   Period: 5 minutes
   ```

2. **Queries stored metrics:**
   ```
   SELECT AVG(CPU_USAGE)
   WHERE host = 'ip-10-0-1-22'
   AND timestamp >= NOW() - 5 minutes
   ```

3. **Evaluates threshold:**
   ```
   If average_cpu > 80%:
     alarm_state = "ALARM"
     trigger_action()
   ```

4. **Triggers SNS notification:**
   ```
   Publish to SNS Topic: VotingApp-Alerts
   Message: "ALARM: CPU usage 85% on Frontend"
   ```

5. **SNS sends email** to `martinkaiser.bln@gmail.com`

---

### Step 7: View in Console

**AWS CloudWatch Console:**

1. Go to: https://console.aws.amazon.com/cloudwatch/
2. Select region: ap-northeast-2
3. Navigate to:
   - **Metrics** → Browse metrics → `VotingApp/Infrastructure`
   - **Alarms** → See alarm status (OK/ALARM)
   - **Dashboards** → Custom visualizations

---

## Why This Architecture?

### Advantages of Push Model (CloudWatch):

1. **Production-Grade:** AWS-managed, highly available
2. **Long Retention:** 15 months vs 15 days
3. **Alerting:** Built-in SNS integration
4. **No Infrastructure:** No Prometheus server to maintain
5. **AWS Integration:** Works with Auto Scaling, Lambda, etc.

### CloudWatch Benefits:

1. **Managed Service:** No servers to maintain
2. **Scalable:** Handles thousands of metrics
3. **Reliable:** 99.9% SLA
4. **Integrated:** Works with all AWS services

---

## 📊 Comparison: Grafana vs CloudWatch

| Aspect | Grafana + Prometheus | CloudWatch |
|--------|---------------------|------------|
| **Data Flow** | Pull (scraping) | Push (agent) |
| **Where Stored** | Frontend instance (local) | AWS (managed) |
| **Retention** | 15 days | 15 months |
| **Cost** | Free | ~$7/month |
| **Update Frequency** | 15 seconds | 60 seconds |
| **Alerting** | Grafana alerts | CloudWatch alarms + SNS |
| **Visualizations** | Beautiful, flexible | Basic, functional |
| **Setup Complexity** | Medium (need Prometheus) | Low (AWS managed) |
| **Best For** | Real-time debugging | Production monitoring |
| **Access** | http://<FRONTEND_IP>:3000 | AWS Console |

---

## 🔄 How They Work Together

```
During Development:
    ↓
Use Grafana for real-time debugging
  • See live CPU, memory spikes
  • Debug performance issues
  • Test stress scenarios

In Production:
    ↓
Use CloudWatch for alerting
  • Email when CPU > 80%
  • Long-term metric storage
  • Compliance and auditing
```

**Both systems run simultaneously!** They complement each other.

---

## 🎯 Key Differences Explained

### Pull vs Push

**Pull (Prometheus):**
```
Prometheus: "Hey Node Exporter, give me your metrics"
Node Exporter: "Here you go: CPU=45%, Memory=60%"
Prometheus: *stores locally*
```

**Push (CloudWatch):**
```
CloudWatch Agent: *collects metrics*
CloudWatch Agent: "Hey AWS, here are my metrics"
AWS CloudWatch: *stores in managed database*
```

### Why Pull for Grafana?

- ✅ **Service Discovery:** Prometheus knows when targets are down
- ✅ **No Agent Configuration:** Just expose metrics endpoint
- ✅ **Centralized Control:** All config in prometheus.yml

### Why Push for CloudWatch?

- ✅ **Firewall Friendly:** Outbound HTTPS only
- ✅ **No External Access:** Private instances can push
- ✅ **Managed:** AWS handles storage, scaling

---

## 🎤 Talking Points for Presentation

### Grafana Explanation:

> "Grafana gets its data through Prometheus, which scrapes metrics every 15 seconds.
>
> Node Exporters run on each instance, exposing system metrics at port 9100. Prometheus pulls these metrics, stores them locally, and Grafana queries Prometheus to display beautiful real-time dashboards.
>
> It's a **pull model** - Prometheus actively fetches data. Perfect for real-time debugging during development."

### CloudWatch Explanation:

> "CloudWatch uses a different approach - the **push model**.
>
> Each instance has a CloudWatch Agent that collects metrics every 60 seconds and pushes them to AWS via HTTPS. The agent uses an IAM role for authentication - no API keys needed.
>
> CloudWatch stores metrics for 15 months and triggers email alerts via SNS when thresholds are exceeded. Perfect for production monitoring and compliance."

### Why Both?

> "I use both because they serve different purposes:
> - **Grafana:** Real-time debugging, beautiful visualizations, free
> - **CloudWatch:** Production alerts, long-term storage, AWS-managed
>
> During the demo, I'll show Grafana because it updates every 15 seconds. But in production, CloudWatch emails me if something goes wrong."

---

## 📚 Summary

### Grafana Data Flow:
```
Node Exporter (exposes) → Prometheus (scrapes) → Time-Series DB (stores)
→ PromQL (queries) → Grafana (visualizes) → Your Browser
```

### CloudWatch Data Flow:
```
System Metrics → CloudWatch Agent (collects) → IAM Role (authenticates)
→ HTTPS POST (pushes) → CloudWatch API → Managed Storage
→ Alarms (evaluate) → SNS (notifies) → Email
```

**Both are running on your infrastructure, giving you complete visibility!** 🚀
