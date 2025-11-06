# Ansible Architecture Explained

Complete explanation of how Ansible works in this DevOps project and why it's used.

---

## 🤔 Why Ansible?

### The Problem Without Ansible:

Imagine deploying to 3 servers **manually**:

```bash
# SSH to each server individually:
ssh frontend → docker pull → docker stop → docker run → verify
ssh backend → docker pull → docker stop → docker run → verify
ssh database → docker pull → docker stop → docker run → verify
```

**Issues:**
- ❌ Repetitive and error-prone
- ❌ Hard to maintain consistency
- ❌ Doesn't scale (what if you have 100 servers?)
- ❌ No rollback capability
- ❌ Manual verification

### The Solution: Ansible

```bash
# One command deploys to ALL servers:
ansible-playbook -i inventory/hosts.yml playbooks/deploy-all.yml
```

**Benefits:**
- ✅ **Idempotent** - Safe to run multiple times
- ✅ **Parallel execution** - Deploys to all servers simultaneously
- ✅ **Declarative** - You describe WHAT you want, not HOW
- ✅ **Agentless** - Uses SSH, no software needed on servers
- ✅ **Self-documenting** - Playbooks are the documentation

---

## 🏗️ Architecture Overview

```
Your Laptop (Control Node)
    │
    ├─ Ansible Engine
    │   ├─ Inventory (hosts.yml) ──→ "Which servers?"
    │   ├─ Playbooks (*.yml)     ──→ "What to do?"
    │   └─ Variables (all.yml)   ──→ "Configuration values"
    │
    └─ SSH Connections
        │
        ├─→ Frontend (<FRONTEND_IP>) ─── Public SSH
        │
        ├─→ Backend (<BACKEND_IP>) ──────── SSH via Frontend (ProxyJump)
        │
        └─→ Database (<DB_IP>) ────── SSH via Frontend (ProxyJump)
```

---

## 📋 Inventory Structure

**File:** `ansible/inventory/hosts.yml`

### What It Does:
Defines **WHERE** to deploy (which servers, how to connect)

### Example:

```yaml
all:
  children:
    frontend:
      hosts:
        frontend-instance:
          ansible_host: <FRONTEND_IP>        # Public IP
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/key.pem

    backend:
      hosts:
        backend-instance:
          ansible_host: <BACKEND_IP>           # Private IP
          ansible_ssh_common_args: '-o ProxyJump=frontend-instance'  # 🛡️ Through bastion!

    database:
      hosts:
        db-instance:
          ansible_host: <DB_IP>          # Private IP
          ansible_ssh_common_args: '-o ProxyJump=frontend-instance'  # 🛡️ Through bastion!
```

### Key Features:

1. **Groups:** `frontend`, `backend`, `database`
   - Run tasks on specific groups: `hosts: backend`

2. **Bastion/Jump Host:** Private instances use `ProxyJump`
   - Ansible automatically SSH through frontend to reach private IPs
   - **This solves Problem #1 from your presentation!**

3. **SSH Key Management:** Single key defined once, reused everywhere

---

## 📖 Playbook Structure

**Playbooks** = Automation scripts in YAML format

### Anatomy of a Playbook:

```yaml
---
- name: Deploy Vote App               # Human-readable description
  hosts: frontend                     # Which servers (from inventory)
  become: no                          # Don't use sudo (run as ubuntu)
  gather_facts: yes                   # Collect server info

  vars_files:                         # Load configuration
    - ../group_vars/all.yml

  tasks:                              # What to do (sequential steps)
    - name: Pull Docker image
      ansible.builtin.command:
        cmd: "docker pull kodekloud/examplevotingapp_vote:latest"

    - name: Stop existing container
      ansible.builtin.command:
        cmd: docker stop vote
      failed_when: false              # Don't fail if container doesn't exist

    - name: Deploy container
      ansible.builtin.command:
        cmd: >
          docker run -d
          --name vote
          --restart always
          -p 80:80
          -e REDIS_HOST=redis
          kodekloud/examplevotingapp_vote:latest

    - name: Verify it's running
      ansible.builtin.command:
        cmd: docker ps --filter name=vote
      changed_when: false             # Don't mark as "changed"
```

### Key Concepts:

1. **Tasks** run sequentially (top to bottom)
2. **Modules** (`command`, `copy`, `apt`, etc.) - building blocks
3. **Idempotency** - Can run multiple times safely
4. **Conditions** - `when:`, `failed_when:`, `changed_when:`

---

## 🎯 The 12 Playbooks

### 1. **Setup Playbooks** (Run Once)

#### `install-docker.yml`
**Purpose:** Install Docker on all instances

```yaml
- Install Docker from official repository
- Add ubuntu user to docker group
- meta: reset_connection  # ⬅️ Fixes group membership! (Problem #2)
- Start Docker service
```

**Why this matters:** Without `meta: reset_connection`, Docker commands fail with permission errors!

---

#### `deploy-monitoring.yml`
**Purpose:** Deploy Prometheus + Grafana stack

```yaml
- Deploy Prometheus (metrics collector) :9090
- Deploy Grafana (visualization) :3000
- Deploy Node Exporters on all instances :9100
- Configure Prometheus targets
```

**Result:** Real-time infrastructure monitoring

---

#### `setup-cloudwatch.yml`
**Purpose:** Install CloudWatch agent on all instances

```yaml
- Download CloudWatch agent
- Install agent package
- Configure IAM role for metrics
- Start CloudWatch agent
- Verify agent status
```

**Result:** Production-grade monitoring with AWS CloudWatch

---

#### `deploy-app-metrics.yml`
**Purpose:** Deploy Redis & Postgres exporters

```yaml
Backend:
  - Deploy Redis Exporter :9121

Database:
  - Deploy Postgres Exporter :9187
```

**Result:** Application-level metrics (queue length, vote counts)

---

### 2. **Deployment Playbooks** (Application Services)

#### `deploy-vote-cli.yml` → Frontend
```yaml
- Pull image: kodekloud/examplevotingapp_vote:latest
- Stop existing container
- Deploy Vote App :80
- Environment: REDIS_HOST, REDIS_PORT
- Verify container running
- Check logs
```

#### `deploy-redis-cli.yml` → Backend
```yaml
- Deploy Redis :6379
- Volume: redis-data (persistent storage)
- Health check configured
```

#### `deploy-worker-cli.yml` → Backend
```yaml
- Deploy Worker (.NET)
- Environment: REDIS_HOST, POSTGRES_HOST
- Network: host mode (for easy connectivity)
```

#### `deploy-database-cli.yml` → Database
```yaml
- Deploy PostgreSQL :5432
- Volume: postgres-data (persistent)
- Initial database: postgres
- Credentials: postgres/postgres
```

#### `deploy-result-cli.yml` → Frontend
```yaml
- Deploy Result App :5001
- Environment: POSTGRES_HOST, POSTGRES_PORT
- Public access for viewing results
```

---

### 3. **Testing & Maintenance Playbooks**

#### `test-connectivity.yml`
**Purpose:** Verify all services can talk to each other

```yaml
Frontend:
  ✓ Can reach Redis (<BACKEND_IP>:6379)?
  ✓ Can reach PostgreSQL (<DB_IP>:5432)?

Backend:
  ✓ Can reach PostgreSQL (<DB_IP>:5432)?

All:
  ✓ Check container environment variables
```

**This answers your question!** It uses `telnet` to test TCP connectivity between services.

**Example:**
```yaml
- name: Test Redis connectivity from frontend
  ansible.builtin.shell: timeout 3 telnet {{ redis_host }} {{ redis_port }}
  register: redis_test
  when: inventory_hostname in groups['frontend']
```

If telnet succeeds → Connection works ✅
If telnet fails → Security group issue or service down ❌

---

#### `check-logs.yml`
**Purpose:** View logs from all containers

```yaml
- Get logs from last 50 lines of each container
- Display formatted output
- Useful for debugging
```

**Usage:**
```bash
ansible-playbook -i inventory/hosts.yml playbooks/check-logs.yml
```

---

#### `stop-all.yml`
**Purpose:** Stop all application containers

```yaml
- Stop vote, result, redis, worker, postgres
- Useful for maintenance or restart
```

---

## 🔄 How Ansible Execution Works

### Step-by-Step Process:

```
1. Read Inventory
   ↓
   Know which servers exist and how to connect

2. Read Playbook
   ↓
   Know what tasks to execute

3. Gather Facts (if gather_facts: yes)
   ↓
   Collect info about each server (OS, IP, memory, etc.)

4. Execute Tasks (Parallel by default across hosts)
   ↓
   Frontend: Pull image → Stop container → Deploy
   Backend:  Pull image → Stop container → Deploy
   Database: Pull image → Stop container → Deploy
   (All happening simultaneously!)

5. Register Results
   ↓
   Capture output of each task

6. Verify & Report
   ↓
   Show success/failure for each task

7. Final Summary
   ↓
   frontend: ok=5 changed=3 failed=0
   backend:  ok=5 changed=3 failed=0
   database: ok=5 changed=3 failed=0
```

---

## 🛡️ Solving Problem #1: Private Network Access

### The Challenge:
Backend (<BACKEND_IP>) and Database (<DB_IP>) have NO public IPs.

### Manual Approach (Without Ansible):
```bash
# Step 1: SSH to bastion
ssh -i key.pem ubuntu@<FRONTEND_IP>

# Step 2: From bastion, SSH to backend
ssh ubuntu@<BACKEND_IP>

# Step 3: Run Docker commands
docker pull ...
docker run ...
```

**Problems:**
- Multi-hop SSH is tedious
- Can't automate easily
- Terraform can't SSH to private instances directly

### Ansible Solution:
```yaml
# Inventory configuration handles it automatically!
backend-instance:
  ansible_host: <BACKEND_IP>
  ansible_ssh_common_args: '-o ProxyJump=frontend-instance'
```

**What happens behind the scenes:**
```
Ansible → SSH to Frontend (<FRONTEND_IP>)
       → From Frontend, SSH to Backend (<BACKEND_IP>)
       → Execute Docker commands
       → Return results to Ansible
```

**One command deploys to private instances:**
```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy-redis-cli.yml
# ✅ Works! Ansible handles the SSH jump automatically
```

**This is why Ansible is critical for private subnet architecture!**

---

## 💡 Why Docker CLI in Playbooks?

You might wonder: Why use `ansible.builtin.command` with Docker CLI instead of `docker_container` module?

### The Answer: Problem #2 from your presentation!

**Docker SDK (community.docker modules):**
```yaml
# ❌ This looks cleaner but TOTALLY FAILS
- name: Deploy Redis
  community.docker.docker_container:
    name: redis
    image: redis:alpine
```

**Issues:**
- Python Docker SDK dependency hell
- urllib3 version conflicts
- `URLSchemeUnknown: Not supported URL scheme http+docker`
- 3 hours wasted debugging!

**Docker CLI (what we use):**
```yaml
# ✅ This works reliably every time
- name: Deploy Redis
  ansible.builtin.command:
    cmd: docker run -d --name redis redis:alpine
```

**Why it works:**
- Docker CLI is battle-tested
- No Python dependencies
- Used by Netflix, Spotify, Google
- **The "correct" tool (SDK) ≠ "right" tool (CLI)**

This is the **slim path in DevOps** - use proven, reliable tools!

---

## 🎯 Complete Deployment Workflow

### Fresh Infrastructure Deployment:

```bash
# 1. Terraform creates infrastructure
cd terraform
terraform apply

# 2. Install Docker on all instances
cd ../ansible
ansible-playbook -i inventory/hosts.yml playbooks/install-docker.yml

# 3. Deploy application services
ansible-playbook -i inventory/hosts.yml playbooks/deploy-redis-cli.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy-database-cli.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy-worker-cli.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy-vote-cli.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy-result-cli.yml

# 4. Deploy monitoring
ansible-playbook -i inventory/hosts.yml playbooks/deploy-monitoring.yml
ansible-playbook -i inventory/hosts.yml playbooks/setup-cloudwatch.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy-app-metrics.yml

# 5. Test connectivity
ansible-playbook -i inventory/hosts.yml playbooks/test-connectivity.yml

# 6. Verify
curl http://<FRONTEND_IP>        # Vote App
curl http://<FRONTEND_IP>:5001   # Result App
curl http://<FRONTEND_IP>:3000   # Grafana
```

---

## 🔍 Testing Playbooks Explained

### `test-connectivity.yml` Deep Dive:

**Purpose:** Verify security groups and network connectivity

**How it works:**

```yaml
# Install telnet on all instances
- name: Install telnet
  ansible.builtin.apt:
    name: telnet
    state: present

# Test from Frontend → Redis (Backend)
- name: Test Redis connectivity from frontend
  ansible.builtin.shell: timeout 3 telnet <BACKEND_IP> 6379
  when: inventory_hostname in groups['frontend']
  register: redis_test

# Check result
- name: Display result
  ansible.builtin.debug:
    msg: "Redis: {{ 'SUCCESS' if redis_test.rc == 0 else 'FAILED' }}"
```

**What it tests:**

| Test | From | To | Verifies |
|------|------|----|---------
| Redis | Frontend (10.0.1.x) | Backend (<BACKEND_IP>:6379) | sg_backend allows 6379 from sg_frontend |
| PostgreSQL (Worker) | Backend (<BACKEND_IP>) | Database (<DB_IP>:5432) | sg_database allows 5432 from sg_backend |
| PostgreSQL (Result) | Frontend (10.0.1.x) | Database (<DB_IP>:5432) | sg_database allows 5432 from sg_frontend |

**Why this matters:**

If security groups are misconfigured:
- Vote App can't reach Redis → ❌ Votes don't queue
- Worker can't reach PostgreSQL → ❌ Votes don't persist
- Result App can't reach PostgreSQL → ❌ Results don't display

**This playbook catches security group errors before deployment fails!**

---

## 🎓 Key Ansible Concepts

### 1. Idempotency

Run the same playbook multiple times → Same result

```yaml
# First run:  Deploys container      (changed: true)
# Second run: Container already exists (changed: false)
# Third run:  Container already exists (changed: false)
```

Safe to run in production!

---

### 2. `changed_when: false`

Tell Ansible a task didn't change anything

```yaml
- name: Check Docker status
  ansible.builtin.command: docker ps
  changed_when: false  # Just checking, not changing
```

---

### 3. `failed_when: false`

Don't fail if task returns error

```yaml
- name: Stop container
  ansible.builtin.command: docker stop redis
  failed_when: false  # OK if container doesn't exist
```

---

### 4. `register:`

Capture task output for later use

```yaml
- name: Get vote count
  ansible.builtin.shell: docker exec postgres psql -c "SELECT COUNT(*)"
  register: vote_count

- name: Display count
  ansible.builtin.debug:
    msg: "Total votes: {{ vote_count.stdout }}"
```

---

### 5. `when:`

Conditional execution

```yaml
- name: Deploy Redis
  ansible.builtin.command: docker run redis
  when: inventory_hostname in groups['backend']
```

---

## 🚀 Why Ansible for This Project?

### 1. **Multi-Server Coordination**
   - 3 servers (frontend, backend, database)
   - Each needs different services deployed
   - Must configure networking between them

### 2. **Private Subnet Challenge**
   - Backend and database have NO public IPs
   - Ansible handles SSH jump host automatically
   - Terraform can't SSH to private instances

### 3. **Docker CLI Reliability**
   - Docker SDK failed (Problem #2)
   - Ansible `command` module works perfectly
   - Industry-standard approach

### 4. **Configuration Management**
   - Single source of truth (`all.yml`)
   - Environment variables consistent
   - IPs managed in one place

### 5. **Testing & Validation**
   - `test-connectivity.yml` catches security group errors
   - `check-logs.yml` for debugging
   - Verify deployment before production

### 6. **Repeatability**
   - Destroy infrastructure → `terraform destroy`
   - Rebuild infrastructure → `terraform apply`
   - Redeploy services → `ansible-playbook ...`
   - **Same result every time**

---

## 📊 Ansible vs. Alternatives

| Tool | Use Case | Why Not Used |
|------|----------|-------------|
| **Bash Scripts** | Simple automation | Hard to maintain, no idempotency, no parallelism |
| **Terraform Provisioners** | One-time setup | Can't SSH to private instances, not idempotent |
| **Docker Compose** | Local development | Doesn't work across multiple servers |
| **Kubernetes** | Container orchestration | Overkill for 3 servers, complex setup |
| **Ansible** ✅ | Configuration management | Perfect for this use case! |

---

## 🎤 Talking Points for Presentation

> "After Terraform creates the infrastructure, I use **Ansible** to deploy the applications. Why Ansible?
>
> 1. **Private subnet problem** - Backend and database have no public IPs. Ansible automatically uses the frontend as a jump host.
>
> 2. **Docker SDK failed** - After 3 hours debugging Docker SDK issues, I switched to Docker CLI through Ansible. This is the pragmatic DevOps approach.
>
> 3. **One command deploys everything** - `ansible-playbook deploy-all.yml` deploys to all 3 servers in parallel.
>
> 4. **Testing built-in** - `test-connectivity.yml` catches security group errors before they cause production issues.
>
> Ansible makes complex multi-server deployments manageable and repeatable."

---

## 📚 Further Reading

- Ansible Docs: https://docs.ansible.com/
- Best Practices: https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html
- Docker CLI Approach: Why community.docker modules aren't production-ready

---

**Summary:** Ansible provides the **automation glue** between Terraform (infrastructure) and Docker (applications), solving the private subnet challenge and enabling reliable, repeatable deployments!
