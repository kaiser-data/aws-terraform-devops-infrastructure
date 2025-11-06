# 🔥 Stress Test Guide - Finding Your Infrastructure Limits

Complete guide to stress testing your voting application infrastructure.

---

## 🎯 What This Tests

The stress test helps you understand:
- **Maximum throughput** - How many votes/second can your system handle?
- **Bottlenecks** - Which tier (Frontend/Backend/Database) hits limits first?
- **Resource usage** - CPU, Memory, Network under heavy load
- **Data integrity** - Do all votes make it through the pipeline?
- **Recovery time** - How long to process the queue?

---

## 🚀 Quick Start

### **Step 1: Open Monitoring**

Before running the test, open these in your browser:

```
Tab 1: Grafana Dashboard
http://3.36.116.222:3000/d/voting-app-demo

Tab 2: Prometheus Graphs
http://3.36.116.222:9090/graph

Tab 3: Result App (to see votes increasing)
http://3.36.116.222:5001
```

### **Step 2: Run Stress Test**

```bash
cd ~/ironhack/project_multistack_devops_app/monitoring
./stress-test.sh
```

### **Step 3: Choose Load Level**

```
🟢 LIGHT     - 100 votes   (Good for first test)
🟡 MODERATE  - 500 votes   (Realistic load)
🔴 HEAVY     - 1000 votes  (High traffic simulation)
💥 EXTREME   - 2000 votes  (Peak load test)
🚀 INSANE    - 5000 votes  (FIND THE LIMITS!)
🎯 CUSTOM    - Your choice
```

---

## 📊 What to Watch During Test

### **In Grafana Dashboard**

Watch these metrics change in real-time:

#### **Network Traffic** (Bottom Left Panel)
```
Before test: ~1-5 KB/s
During test: SPIKE to 50-200 KB/s
After test:  Returns to baseline

What it shows: Data flowing Vote App → Redis
```

#### **Frontend CPU** (Top Left)
```
Before test: 1-5%
During test: 10-30% spike
After test:  Gradual decrease

What it shows: Vote App receiving HTTP requests
```

#### **Backend CPU** (Top Middle)
```
Before test: 1-5%
During test: 20-60% spike (Worker processing!)
After test:  Stays high until queue empty

What it shows: .NET Worker processing Redis queue
```

#### **Database CPU** (Top Right)
```
Before test: 1-5%
During test: 10-20% increase
After test:  Returns to baseline

What it shows: PostgreSQL writing votes
```

#### **System Load Gauges** (Bottom Right)
```
Normal: 0.0 - 0.5
Under load: 1.0 - 3.0
Stressed: > 3.0

Shows: Overall system stress
```

### **In Prometheus**

Try these queries during the test:

```promql
# Network traffic rate
rate(node_network_receive_bytes_total{instance="frontend"}[1m])

# CPU usage
100 - (avg(rate(node_cpu_seconds_total{mode="idle",instance="backend"}[1m])) * 100)

# Memory available
node_memory_MemAvailable_bytes{instance="backend"}
```

### **In Result App**

- Watch the vote count climbing rapidly
- Should see smooth, continuous updates
- Final count should match stress test numbers

---

## 📈 Understanding Results

### **Sample Output Explained**

```
═══════════════════════════════════════════════════════
📊 Test Results:
═══════════════════════════════════════════════════════
  Total Votes Sent:     1000
  Duration:             25 seconds
  Throughput:           40.00 votes/second
  Parallel Connections: 40
═══════════════════════════════════════════════════════

💾 Database Results:
═══════════════════════════════════════════════════════
  Initial Count:  56
  Final Count:    1056
  New Votes:      1000
  Success Rate:   100.00%
═══════════════════════════════════════════════════════
```

### **Interpreting Success Rate**

- **100%** - Perfect! All votes processed
- **95-99%** - Excellent, minor data loss
- **90-95%** - Good, some queuing issues
- **< 90%** - System under stress, investigate

### **Throughput Benchmarks**

**For t3.micro instances (1 vCPU, 1GB RAM):**

| Throughput | Rating | Meaning |
|------------|--------|---------|
| > 50/sec | 🚀 Excellent | System handles load easily |
| 30-50/sec | ✅ Good | Healthy performance |
| 15-30/sec | ⚠️ Fair | Approaching limits |
| < 15/sec | ❌ Poor | System struggling |

---

## 🔍 Finding Bottlenecks

### **Bottleneck Detection**

Run tests and watch which component hits 80%+ CPU first:

```bash
# During test, run:
ssh frontend-instance "top -bn1 | head -20"
ssh backend-instance "top -bn1 | head -20"
ssh db-instance "top -bn1 | head -20"
```

**Common Bottlenecks:**

#### **1. Frontend (Vote App) Bottleneck**
```
Symptoms:
- Frontend CPU > 80%
- Backend CPU < 50%
- Slow response times

Solutions:
- Add more frontend instances
- Use Application Load Balancer
- Increase frontend instance size
```

#### **2. Backend (Worker) Bottleneck**
```
Symptoms:
- Backend CPU > 80%
- Redis queue growing
- Delayed vote processing

Solutions:
- Add more Worker instances
- Scale horizontally
- Optimize Worker code
```

#### **3. Database Bottleneck**
```
Symptoms:
- Database CPU > 80%
- Slow writes
- Connection pool exhaustion

Solutions:
- Upgrade to RDS with read replicas
- Add connection pooling
- Optimize queries
```

#### **4. Network Bottleneck**
```
Symptoms:
- High packet loss
- Timeouts
- Network traffic > 90% capacity

Solutions:
- Upgrade instance network capacity
- Use enhanced networking
- Add CloudFront CDN
```

---

## 🎓 Presentation Tips

### **During Demo Say:**

> "Let me show you how the system handles high load. I'll simulate 1000 concurrent users voting..."

**Run the test, then explain:**

> "Watch the Grafana dashboard - you can see:
> - Network traffic spiking as votes come in
> - Backend CPU increasing as the Worker processes them
> - All votes being stored in the database
> - The system handling 40 votes per second on basic infrastructure"

### **Impressive Stats to Mention:**

- **Throughput**: "Processing 40-50 votes per second"
- **Reliability**: "100% success rate, no data loss"
- **Scalability**: "Running on t3.micro instances, could scale to t3.xlarge for 10x capacity"
- **Monitoring**: "Real-time visibility into every tier"

### **Advanced Discussion Points:**

1. **"How would you scale this?"**
   - Add Auto Scaling Groups
   - Use Application Load Balancer
   - Migrate to RDS and ElastiCache
   - Implement horizontal scaling

2. **"What are the current limits?"**
   - Show actual bottleneck from test
   - Explain instance size constraints
   - Discuss cost vs. performance trade-offs

3. **"How do you ensure reliability?"**
   - Point to 100% success rate
   - Explain queue-based architecture
   - Discuss retry mechanisms

---

## 🧪 Advanced Tests

### **Sustained Load Test**

Test how system performs over time:

```bash
# Run multiple tests back-to-back
for i in {1..5}; do
  echo "Test $i of 5"
  ./stress-test.sh
  sleep 30
done
```

### **Gradual Ramp-Up**

Test system under increasing load:

```bash
# Custom test with increasing load
./stress-test.sh  # Choose Custom
# Run: 100, then 500, then 1000, then 2000
```

### **Queue Observation**

Watch Redis queue during test:

```bash
# In another terminal
ssh backend-instance "watch -n 1 'docker exec redis redis-cli llen votes'"
```

---

## 📊 Metrics to Capture for Presentation

### **Take Screenshots Of:**

1. **Before Test**: Baseline metrics (calm graphs)
2. **During Test**: Spikes in all metrics
3. **After Test**: Recovery to baseline
4. **Final Results**: Terminal output showing stats

### **Create Performance Graph:**

```
Load Level    | Votes | Time | Rate (v/s) | Success
--------------|-------|------|------------|--------
Light         | 100   | 10s  | 10.0       | 100%
Moderate      | 500   | 25s  | 20.0       | 100%
Heavy         | 1000  | 25s  | 40.0       | 99.8%
Extreme       | 2000  | 45s  | 44.4       | 98.5%
```

---

## ⚠️ Important Notes

### **Cost Considerations**

- NAT Gateway charges for data transfer
- Keep tests short to minimize costs
- Stop instances when not in use

### **System Recovery**

After heavy tests, allow 1-2 minutes for:
- Worker to finish processing queue
- CPU to return to normal
- Memory to stabilize

### **Database Cleanup**

To reset vote counts for clean demo:

```bash
ssh db-instance "docker exec postgres psql -U postgres -d postgres -c 'TRUNCATE votes;'"
```

---

## 🎯 Expected Results on t3.micro

**Theoretical Maximum:**
- Network: 5 Gbps burst
- CPU: 2 vCPU (burstable)
- Memory: 1 GB

**Real-World Performance:**
```
Light Test:    ✅ Easy (10% CPU)
Moderate Test: ✅ Comfortable (30% CPU)
Heavy Test:    ⚠️ Stressed (60-80% CPU)
Extreme Test:  ❌ Near Limit (80-95% CPU)
Insane Test:   ❌ Bottlenecked (queuing delays)
```

---

## 🚀 Scaling Recommendations

### **To 10x Capacity:**

1. **Vertical Scaling** (Quick)
   - t3.micro → t3.large
   - Cost: ~$60/month → ~$180/month
   - Capacity: 50 v/s → 500 v/s

2. **Horizontal Scaling** (Better)
   - Add Auto Scaling Groups
   - Add Application Load Balancer
   - Multiple frontend/worker instances
   - Capacity: Limited only by instances

3. **Managed Services** (Best)
   - RDS for PostgreSQL
   - ElastiCache for Redis
   - ECS/EKS for containers
   - Capacity: Enterprise-grade

---

## 📝 Test Checklist for Presentation

- [ ] Grafana dashboard open and visible
- [ ] Prometheus targets showing all UP
- [ ] Result app visible
- [ ] Stress test script ready
- [ ] SSH access to instances working
- [ ] Database has initial votes for comparison
- [ ] Screenshots of key metrics saved

---

**Ready to find your limits! 🔥**

*Remember: These are t3.micro instances - impressive they handle this load at all!*
