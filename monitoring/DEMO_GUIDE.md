# Demo Guide - Presentation Setup

Quick guide for preparing and running the live demo during your presentation.

---

## 📝 Pre-Demo Setup

### 1. Reset Database (Clean Start)

Before your presentation, clear all existing votes:

```bash
cd /home/marty/ironhack/project_multistack_devops_app/monitoring
./reset-database.sh
```

**What it does:**
- Shows current vote count
- Asks for confirmation (type `yes`)
- Truncates the votes table (deletes all votes)
- Shows new count (should be 0)

**Expected Output:**
```
🗑️  Database Reset Script
========================

📊 Current vote count:
     523

⚠️  Are you sure you want to DELETE ALL VOTES? (yes/no): yes

🔄 Clearing all votes...
✅ Database reset complete!

📊 New vote count:
     0

🎬 Ready for demo!
```

---

## 🎬 During Presentation Demo

### 2. Vote Dramatically - Show Movement!

**Option A: Random Voting (60% Cats, 40% Dogs)**
```bash
./quick-stress.sh 500 20
```

**Option B: Vote for CATS** 🐱
```bash
./vote-cats.sh 1000 40
```

**Option C: Vote for DOGS** 🐶
```bash
./vote-dogs.sh 1000 40
```

**Demo Strategy for Maximum Impact:**
1. Reset database → Start at 0-0
2. Vote for cats: `./vote-cats.sh 500 40` → Cats lead 500-0
3. Show Result App → Cats winning big!
4. Vote for dogs: `./vote-dogs.sh 1000 40` → Dogs comeback!
5. Refresh Result App → Dogs now winning 1000-500!
6. **This shows dramatic movement and live updates!**

**Expected Output:**
```
🔥 Quick Stress Test - Random Voting
Votes: 500 | Parallel: 20
Distribution: 60% Cats 🐱, 40% Dogs 🐶

Starting in 3 seconds...
Sending votes: ....................................................

✅ Complete!
Duration: 12s
Rate: 41.66 votes/sec

📊 Check results at: http://3.36.116.222:5001
```

### 3. Show Results

Open in browser **during the demo**:

1. **Result App:** http://3.36.116.222:5001
   - Shows real-time vote counts
   - Cats should be winning (≈60%)

2. **Grafana Dashboard:** http://3.36.116.222:3000
   - Shows CPU, Memory spikes during stress test
   - Dashboard: "Voting Application Architecture"

---

## 📊 What to Show the Audience

### Step 1: Show Empty Database
- Open Result App before test
- Should show 0 votes (or minimal votes)

### Step 2: Run Stress Test
- Run `./quick-stress.sh 500 20` in terminal
- Show the progress dots
- Point out the "41.66 votes/sec" throughput

### Step 3: Verify Results
- Refresh Result App immediately
- **Key Point:** Might not show exactly 500 votes yet (retention issue!)
- Wait 5-10 seconds, refresh again
- Now should show ≈500 votes with Cats winning

### Step 4: Show Monitoring
- Switch to Grafana dashboard
- Show CPU/Memory spikes during the test
- Point out Frontend CPU increased during load

---

## 🎯 Key Demo Talking Points

1. **Random Voting:**
   - "The stress test votes randomly - 60% cats, 40% dogs"
   - "Watch the Result App show cats winning"

2. **Latency Issue (Problem #3):**
   - "Notice right after test: might show 487 votes, not 500"
   - "This is the retention issue - Worker is still processing"
   - "Wait 10 seconds... refresh... now 500 votes!"
   - **This proves your Problem #3 point!**

3. **Monitoring:**
   - "Grafana shows infrastructure metrics in real-time"
   - "CPU spiked to 40-80% during test"
   - "But CPU isn't the bottleneck - message queue is"

4. **Throughput:**
   - "41.66 votes per second on t3.micro instances"
   - "That's the real throughput, measured end-to-end"

---

## 🚨 Troubleshooting

### Database Reset Fails
```bash
# Manual reset through bastion
ssh -i ~/.ssh/voting-app-key.pem ubuntu@3.36.116.222
ssh ubuntu@10.0.2.115
docker exec postgres psql -U postgres -d postgres -c "TRUNCATE votes;"
```

### Stress Test Shows Connection Errors
- Check Vote App is running: `curl http://3.36.116.222:80`
- Should return HTML with voting form

### Result App Not Updating
- Wait 10-20 seconds (Worker latency)
- Check Worker is running: `ssh ubuntu@10.0.2.75` → `docker ps`

---

## 📋 Complete Demo Checklist

Before presentation:
- [ ] Reset database: `./reset-database.sh`
- [ ] Verify Result App shows 0 votes
- [ ] Open Grafana dashboard in browser tab
- [ ] Open Result App in browser tab
- [ ] Terminal ready at monitoring directory

During demo:
- [ ] Show Result App (empty)
- [ ] Run `./quick-stress.sh 500 20`
- [ ] Show immediate results (might be incomplete)
- [ ] Wait 10 seconds, refresh (now complete)
- [ ] Show Grafana metrics
- [ ] Explain the latency issue (Problem #3)

---

## 🎤 Demo Script Example

> "Let me show you this in action. I'll reset the database to start fresh..."
>
> `./reset-database.sh` (type yes)
>
> "Now we have 0 votes. Let me run a stress test with 500 random votes - 60% cats, 40% dogs..."
>
> `./quick-stress.sh 500 20`
>
> "Watch this... 41.66 votes per second. Let's check the results..."
>
> (Refresh Result App)
>
> "See? Only 487 votes. Where are the other 13? This is Problem #3 - the retention issue. The Worker is still processing votes from the Redis queue. Let's wait 10 seconds..."
>
> (Wait, refresh)
>
> "Now we see all 500 votes! And look - cats are winning with about 300 votes, dogs have about 200. That's the 60/40 distribution."
>
> (Switch to Grafana)
>
> "Here in Grafana, you can see the CPU spiked during the test. But it's not the bottleneck - the message queue is. That's why we measure end-to-end."

---

**Good luck with your presentation!** 🎤🚀
