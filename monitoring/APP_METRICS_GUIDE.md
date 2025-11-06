# Application Metrics Guide

## ✅ What's Available Now

You now have **application-level metrics** in Prometheus/Grafana!

### 1. **Database Metrics** (Postgres Exporter)
- Vote count in database
- Database connections
- Query performance
- Table sizes

### 2. **Redis Metrics** (Redis Exporter)
- Queue length (votes waiting to process)
- Memory usage
- Commands per second
- Connected clients

---

## 📊 Key Metrics for Your Demo

### Vote Count in Database

**Prometheus Query:**
```promql
pg_stat_database_numbackends{datname="postgres"}
```

Or for vote count directly:
```sql
-- This requires a custom query, Postgres exporter doesn't expose table row counts by default
-- We'll need to query the database directly or add a custom metric
```

### Redis Queue Length (Votes Waiting)

**Prometheus Query:**
```promql
redis_list_length{job="redis"}
```

This shows how many votes are waiting in the Redis queue to be processed by the Worker.

### Migration Speed (Votes/Second)

**Prometheus Query - Rate of change:**
```promql
rate(pg_stat_database_xact_commit{datname="postgres"}[1m])
```

This shows transaction rate (inserts per second).

---

## 🎨 Adding to Grafana Dashboard

### Quick Add Panels:

1. **Go to Grafana:** http://3.36.116.222:3000
2. **Open Dashboard:** "Voting Application Architecture"
3. **Click "Add Panel"** (top right)
4. **Add these queries:**

#### Panel 1: Redis Queue Length
```
Metric: redis_list_length
Title: "Votes in Queue (Redis)"
Description: "Votes waiting to be processed by Worker"
```

#### Panel 2: Database Activity
```
Metric: rate(pg_stat_database_xact_commit{datname="postgres"}[1m])
Title: "Database Transactions/sec"
Description: "Vote inserts per second"
```

#### Panel 3: Redis Commands
```
Metric: rate(redis_commands_processed_total[1m])
Title: "Redis Commands/sec"
Description: "Queue operations per second"
```

---

## 🔍 Prometheus Queries for Demo

### Check Redis is Working:
```bash
curl -s http://10.0.2.75:9121/metrics | grep redis_connected_clients
```

### Check Postgres Exporter:
```bash
curl -s http://10.0.2.115:9187/metrics | grep pg_stat_database
```

### Check Prometheus Targets:
```bash
curl -s http://3.36.116.222:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="redis" or .labels.job=="postgres") | {job:.labels.job, health:.health}'
```

---

## 🎬 Demo Flow with Application Metrics

1. **Before Stress Test:**
   - Show Grafana dashboard
   - Point out Redis queue length = 0
   - Database transaction rate = low

2. **During Stress Test:**
   ```bash
   ./quick-stress.sh 500 20
   ```
   - Watch Redis queue length spike!
   - Database transaction rate increases
   - This shows the migration happening!

3. **After Stress Test:**
   - Redis queue gradually drains to 0
   - This is the **retention issue** (Problem #3)
   - Worker takes time to process all votes

---

## 💡 Key Talking Points

### "See the Migration Speed"
> "When I send 500 votes, watch the Redis queue. It spikes to 500, then gradually drains as the Worker processes votes and inserts them into PostgreSQL. The transaction rate shows how fast votes are migrating."

### "This is the Retention Issue"
> "Notice after the stress test ends, the Redis queue doesn't go to zero immediately. It takes 10-20 seconds. This is Problem #3 - the latency between Redis and the database."

### "Real-Time Monitoring"
> "With these metrics, we can see exactly what's happening:
> - Votes arrive in Redis (queue length increases)
> - Worker processes them (queue drains, DB transactions spike)
> - Eventually all votes make it to PostgreSQL"

---

## 🎯 What Each Metric Shows

| Metric | What It Measures | Why It Matters |
|--------|------------------|----------------|
| **redis_list_length** | Votes in queue | Shows backlog, processing lag |
| **pg_stat_database_xact_commit** | DB transactions/sec | Shows Worker processing speed |
| **redis_commands_processed_total** | Redis operations | Shows queue activity |
| **pg_stat_database_numbackends** | Active DB connections | Shows Worker connections |

---

## 🚀 Quick Test

```bash
# Reset database
./reset-db-simple.sh

# Send votes
./quick-stress.sh 100 10

# Check Redis queue (should be > 0 initially)
curl -s http://10.0.2.75:9121/metrics | grep 'redis_list_length{' | grep -v '#'

# Wait 10 seconds

# Check again (should be 0 or near 0)
curl -s http://10.0.2.75:9121/metrics | grep 'redis_list_length{' | grep -v '#'
```

---

## 📝 Manual Dashboard Update

If you want to manually add these panels to Grafana:

1. Login to Grafana: http://3.36.116.222:3000 (admin/admin)
2. Go to Dashboards → Voting Application Architecture
3. Click "Add" → "Visualization"
4. Select "Prometheus" as data source
5. Enter one of the queries above
6. Configure panel (title, type, colors)
7. Click "Apply"
8. Click "Save dashboard" (💾 icon top right)

---

## 🎤 Demo Script Addition

After showing the stress test results:

> "And here's something really cool - we can see what's happening inside the application. Look at this Redis queue metric..."
>
> (Point to Grafana panel with redis_list_length)
>
> "See how it spiked to 500 during the stress test? That's all the votes waiting in Redis. Now watch it drain... the Worker is pulling votes out and inserting them into PostgreSQL."
>
> (Point to database transaction rate)
>
> "This shows the migration speed - about 50 votes per second. This latency is why we saw the retention issue. The votes are in Redis immediately, but take time to reach the database."

---

**Application metrics are now live!** 🎉

Check Prometheus targets: http://3.36.116.222:9090/targets
- ✅ Redis exporter (port 9121)
- ✅ Postgres exporter (port 9187)
