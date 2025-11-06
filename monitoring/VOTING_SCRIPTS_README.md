# Voting Scripts - Quick Reference

All voting scripts for your presentation demo.

---

## 📝 Available Scripts

### 1. **Reset Database**
```bash
./reset-db-simple.sh
```
- Clears all votes from database
- Shows before/after vote count
- Use before each demo

---

### 2. **Random Voting** (60% Cats, 40% Dogs)
```bash
./quick-stress.sh [votes] [parallel]

# Examples:
./quick-stress.sh 100 10    # 100 votes, 10 parallel
./quick-stress.sh 500 20    # 500 votes, 20 parallel
./quick-stress.sh 1000 40   # 1000 votes, 40 parallel (default)
```

**Use when:** You want realistic mixed voting

---

### 3. **Vote for CATS** 🐱
```bash
./vote-cats.sh [votes] [parallel]

# Examples:
./vote-cats.sh 500 40       # 500 cat votes
./vote-cats.sh 1000 40      # 1000 cat votes (default)
```

**Use when:** You want cats to win or show a comeback

---

### 4. **Vote for DOGS** 🐶
```bash
./vote-dogs.sh [votes] [parallel]

# Examples:
./vote-dogs.sh 500 40       # 500 dog votes
./vote-dogs.sh 1000 40      # 1000 dog votes (default)
```

**Use when:** You want dogs to win or show dramatic movement

---

### 5. **Check Vote Distribution**
```bash
./check-votes.sh
```

**Shows:**
- 🐱 Cats: [count]
- 🐶 Dogs: [count]
- Total: [count]

---

## 🎬 Demo Scenarios

### Scenario 1: "The Comeback"
Perfect for showing live updates and dramatic movement!

```bash
# 1. Reset
./reset-db-simple.sh

# 2. Cats take early lead
./vote-cats.sh 500 40

# 3. Show Result App (refresh browser)
# Should show: Cats 500 - Dogs 0

# 4. Dogs make comeback!
./vote-dogs.sh 1000 40

# 5. Show Result App again (refresh)
# Should show: Cats 500 - Dogs 1000
```

**Talking Points:**
- "Watch how fast the results update in real-time"
- "This is handling 1000+ votes with parallel connections"
- "Notice the latency - votes take 10-20 seconds to fully process"

---

### Scenario 2: "Realistic Random Voting"
Best for showing natural vote distribution.

```bash
# 1. Reset
./reset-db-simple.sh

# 2. Random votes (60% cats, 40% dogs)
./quick-stress.sh 500 20

# 3. Show Result App
# Should show: ~300 cats, ~200 dogs
```

**Talking Points:**
- "Random voting with 60% cat preference"
- "Cats slightly winning as expected"
- "This simulates realistic user behavior"

---

### Scenario 3: "Performance Testing"
Show infrastructure limits and throughput.

```bash
# 1. Reset
./reset-db-simple.sh

# 2. Heavy load test
./quick-stress.sh 1000 40

# 3. Check Grafana during test
# CPU should spike to 40-80%

# 4. Verify all votes arrived
./check-votes.sh
```

**Talking Points:**
- "Sending 1000 votes in parallel"
- "Watch CPU and memory in Grafana"
- "Achieving ~40-45 votes per second"
- "All votes accounted for - 100% data integrity"

---

## 🎯 Parameters Explained

**[votes]** - Number of votes to send
- Recommended: 100-1000
- Higher = more impressive, but takes longer

**[parallel]** - Number of parallel connections
- Recommended: 10-40
- Higher = faster throughput
- Too high (>50) may overwhelm t3.micro instances

---

## ⚡ Quick Commands

```bash
# Fast test (10 votes)
./quick-stress.sh 10 5

# Medium demo (500 votes)
./quick-stress.sh 500 20

# Full demo (1000 votes)
./quick-stress.sh 1000 40

# Extreme test (push limits)
./stress-test.sh   # Interactive menu
```

---

## 📊 Expected Performance

| Votes | Parallel | Duration | Rate |
|-------|----------|----------|------|
| 100 | 10 | ~5s | 20 votes/sec |
| 500 | 20 | ~12s | 41 votes/sec |
| 1000 | 40 | ~24s | 41 votes/sec |

---

## 🐛 Troubleshooting

### Votes not showing up?
```bash
# Wait 10 seconds for Worker to process
sleep 10

# Check database directly
./check-votes.sh
```

### Want to see which option won?
```bash
curl -s http://3.36.116.222:5001 | grep -oP 'data-[ab]="[0-9]+"'
```

### Want to clear everything?
```bash
./reset-db-simple.sh
# Type: yes
```

---

## 🎤 Script for Presentation

> "Let me show you this in action. I'll start with a clean database..."
>
> `./reset-db-simple.sh` → 0 votes
>
> "Now let's send 500 votes for cats..."
>
> `./vote-cats.sh 500 40` → Cats winning!
>
> "And now 1000 votes for dogs..."
>
> `./vote-dogs.sh 1000 40` → Dogs comeback!
>
> "See how the Result App updates in real-time? That's our polyglot architecture in action - Python Flask receiving votes, Redis queuing them, .NET Worker processing, PostgreSQL storing, and Node.js displaying results!"

---

**All scripts located in:** `/home/marty/ironhack/project_multistack_devops_app/monitoring/`

**Result App:** http://3.36.116.222:5001
**Grafana:** http://3.36.116.222:3000
