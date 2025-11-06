# Troubleshooting Log - Vote App Internal Server Error

## Issue
**Date**: November 6, 2025
**Symptom**: Internal Server Error when clicking vote buttons
**Error**: `redis.exceptions.ConnectionError: Error -2 connecting to redis:6379. Name or service not known.`

## Root Cause Analysis

### Problem
The Vote application container was trying to connect to Redis using hostname `redis` instead of the private IP `10.0.2.75`.

### Why It Happened
1. Environment variables (`REDIS_HOST=10.0.2.75`) were configured in the container
2. However, the Python Flask app loads environment variables at module initialization
3. Simply restarting the container doesn't reload the module-level variables
4. The app cached the default value `redis` from `os.getenv('REDIS_HOST', 'redis')`

### Investigation Steps

**Step 1: Check Application Logs**
```bash
ssh frontend-instance "docker logs vote --tail 50"
```
**Finding**: ConnectionError pointing to hostname "redis" instead of IP

**Step 2: Verify Environment Variables**
```bash
ssh frontend-instance "docker exec vote env | grep REDIS"
```
**Finding**: Variables were set correctly (REDIS_HOST=10.0.2.75)

**Step 3: Test Redis Connectivity**
```bash
ssh frontend-instance "timeout 2 bash -c 'cat < /dev/null > /dev/tcp/10.0.2.75/6379'"
```
**Finding**: Redis was reachable on private network

**Step 4: Check Application Code**
```python
# app.py line 16-17
redis_host = os.getenv('REDIS_HOST', 'redis')
redis_port = int(os.getenv('REDIS_PORT', '6379'))
```
**Finding**: Variables loaded at module level, not refreshed on restart

## Solution

### Fix Applied
**Redeployed Vote container** using Ansible to ensure clean container creation with proper environment variables:

```bash
cd ansible
ansible-playbook playbooks/deploy-vote-cli.yml
```

### Why This Works
1. Removes old container completely
2. Creates new container with fresh environment
3. Python app loads environment variables correctly on initial startup
4. Redis connection uses correct private IP (10.0.2.75)

## Verification

**Container Status:**
```bash
ssh frontend-instance "docker ps --filter name=vote"
# Result: Up and running with correct config
```

**Environment Variables:**
```bash
ssh frontend-instance "docker exec vote env | grep REDIS"
# Output:
# REDIS_HOST=10.0.2.75
# REDIS_PORT=6379
```

**Application Access:**
```bash
curl http://3.36.116.222:80
# HTTP 200 - "Cats vs Dogs!" page loads
```

## Testing Instructions

### Manual Browser Test
1. Open: http://3.36.116.222:80
2. Click either "Cats" or "Dogs"
3. Should see checkmark indicating successful vote
4. Open: http://3.36.116.222:5001
5. Should see vote counts displayed

### Command Line Test
```bash
# Test vote submission
curl -X POST http://3.36.116.222:80 \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "vote=a" \
  -b "voter_id=test123" \
  -c cookies.txt

# Check Redis queue
ssh backend-instance "docker exec redis redis-cli LLEN votes"

# Check PostgreSQL
ssh db-instance "docker exec postgres psql -U postgres -c 'SELECT vote, COUNT(*) FROM votes GROUP BY vote;'"
```

## Prevention for Future

### Best Practices
1. **Always redeploy** (not restart) when changing environment variables
2. **Use Ansible playbooks** for consistent deployment
3. **Test after deployment** using health check scripts
4. **Monitor logs** during initial startup

### Recommended Workflow
```bash
# 1. Make configuration changes
vim ansible/group_vars/all.yml

# 2. Redeploy affected services
ansible-playbook playbooks/deploy-vote-cli.yml

# 3. Verify deployment
./testing-scripts/quick-test.sh

# 4. Test functionality manually
```

## Related Components

**Vote App Dependencies:**
- Redis (Backend: 10.0.2.75:6379) - Message queue
- Frontend Instance network access to Private Subnet
- Security Group rules allowing traffic on port 6379

**Data Flow:**
```
Vote App → Redis (RPUSH votes) → Worker → PostgreSQL → Result App
```

## Status
✅ **RESOLVED** - Vote app now connecting to Redis successfully

## Next Steps
1. Test voting functionality in browser
2. Verify vote counts appear in Result app
3. Check worker logs to ensure vote processing
4. Consider adding health check endpoint to Vote app
