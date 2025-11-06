# Ansible Control Node Architecture

## 📍 Where is the Control Node?

**The Ansible control node is YOUR LOCAL MACHINE!**

```
Control Node: Nimzowitsch (your laptop/workstation)
Location: /home/marty/ironhack/project_multistack_devops_app/
```

---

## 🏗️ Complete Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  CONTROL NODE (Your Laptop)                                 │
│  Hostname: Nimzowitsch                                       │
│  OS: Linux 6.8.0-87-generic                                  │
│  Location: /home/marty/ironhack/project_multistack_devops_app/│
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Ansible Engine                                       │  │
│  │  - Version: 2.16.3                                    │  │
│  │  - Installed: /usr/bin/ansible                        │  │
│  │  - Inventory: ansible/inventory/hosts.yml             │  │
│  │  - Playbooks: ansible/playbooks/*.yml                 │  │
│  │  - SSH Key: ~/.ssh/martin-ap-northeast-2-key.pem     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                               │
│  You run commands here:                                      │
│  $ ansible-playbook -i inventory/hosts.yml playbooks/...    │
│                                                               │
└───────────────┬─────────────────────────────────────────────┘
                │
                │ SSH over Internet
                │
                ▼
┌───────────────────────────────────────────────────────────────┐
│  AWS CLOUD (ap-northeast-2)                                   │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  VPC: time_circuit (10.0.0.0/16)                    │    │
│  │                                                       │    │
│  │  ┌─────────────── Public Subnet ──────────────────┐ │    │
│  │  │  10.0.1.0/24                                    │ │    │
│  │  │                                                  │ │    │
│  │  │  ┌──────────────────────────────────────────┐  │ │    │
│  │  │  │  🛡️ Frontend (Bastion + Apps)           │  │ │    │
│  │  │  │  Public IP: 3.36.116.222                 │  │ │    │
│  │  │  │  Private IP: 10.0.1.22                   │  │ │    │
│  │  │  │  - Vote App                              │  │ │    │
│  │  │  │  - Result App                            │  │ │    │
│  │  │  │  - Prometheus                            │  │ │    │
│  │  │  │  - Grafana                               │  │ │    │
│  │  │  └──────────────────────────────────────────┘  │ │    │
│  │  └──────────────────┬─────────────────────────────┘ │    │
│  │                     │                                │    │
│  │                   NAT GW                             │    │
│  │                     │                                │    │
│  │  ┌──────────────── Private Subnet ─────────────────┐ │    │
│  │  │  10.0.2.0/24 (NO INTERNET DIRECT ACCESS)        │ │    │
│  │  │                                                  │ │    │
│  │  │  ┌────────────────┐    ┌──────────────────┐   │ │    │
│  │  │  │  Backend       │    │  Database        │   │ │    │
│  │  │  │  10.0.2.75     │    │  10.0.2.115      │   │ │    │
│  │  │  │  - Redis       │    │  - PostgreSQL    │   │ │    │
│  │  │  │  - Worker      │    │  - Exporters     │   │ │    │
│  │  │  │  - Exporters   │    │                  │   │ │    │
│  │  │  └────────────────┘    └──────────────────┘   │ │    │
│  │  │                                                  │ │    │
│  │  └──────────────────────────────────────────────────┘ │    │
│  └─────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────┘
```

---

## 🔑 Key Concepts

### 1. **Agentless Architecture**

Ansible does NOT install any software on the managed nodes (AWS instances).

```
Control Node (Your Laptop):
  ✅ Has Ansible installed
  ✅ Has SSH client
  ✅ Has inventory and playbooks

Managed Nodes (AWS Instances):
  ❌ NO Ansible installed
  ❌ NO agents running
  ✅ Just need: SSH server + Python (Ubuntu has both by default)
```

**This is a HUGE advantage over other tools:**
- Chef/Puppet → Need agents on every server
- Ansible → Just SSH (already there!)

---

### 2. **SSH Connection Flow**

#### Direct Connection (Frontend):
```
Your Laptop
    │
    └─ SSH to 3.36.116.222 (Frontend public IP)
       └─ Execute: docker ps, docker run, etc.
```

#### Proxied Connection (Private Instances):
```
Your Laptop
    │
    └─ SSH to 3.36.116.222 (Frontend)
       │
       └─ From Frontend, SSH to 10.0.2.75 (Backend)
          └─ Execute: docker ps, docker run, etc.
```

**Ansible handles this automatically with ProxyJump:**

```yaml
# In inventory/hosts.yml
backend-instance:
  ansible_host: 10.0.2.75
  ansible_ssh_common_args: '-o ProxyJump=frontend-instance'
```

One command from your laptop reaches private instances! ✅

---

## 🚀 How Commands Execute

### Example: Deploying Redis

**You run on your laptop:**
```bash
cd /home/marty/ironhack/project_multistack_devops_app/ansible
ansible-playbook -i inventory/hosts.yml playbooks/deploy-redis-cli.yml
```

**What happens:**

```
Step 1: Ansible reads inventory
  ↓
  Target: backend-instance (10.0.2.75)
  Connection: SSH via ProxyJump through frontend-instance

Step 2: Ansible establishes SSH connection
  ↓
  Your Laptop → SSH → Frontend (3.36.116.222)
              → SSH → Backend (10.0.2.75)

Step 3: Ansible gathers facts
  ↓
  Runs: python3 -c "import platform; print(platform.system())"
  Collects: OS, IP addresses, memory, disk, etc.

Step 4: Ansible executes tasks
  ↓
  Task 1: docker pull redis:alpine
  Task 2: docker stop redis
  Task 3: docker rm redis
  Task 4: docker run -d --name redis ...

Step 5: Ansible collects results
  ↓
  Each task returns: success/failed/changed

Step 6: Ansible shows summary
  ↓
  backend-instance: ok=5 changed=3 unreachable=0 failed=0

Step 7: Connection closes
  ↓
  SSH sessions terminated
```

**All from your laptop!** You never manually SSH to the instances.

---

## 📁 Control Node File Structure

```
/home/marty/ironhack/project_multistack_devops_app/
│
├── terraform/              # Infrastructure as Code
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfstate   # Tracks AWS resources
│
├── ansible/                # Configuration Management
│   ├── inventory/
│   │   └── hosts.yml      # ⬅️ Defines managed nodes
│   │
│   ├── group_vars/
│   │   └── all.yml        # Variables (IPs, ports, images)
│   │
│   └── playbooks/
│       ├── install-docker.yml
│       ├── deploy-vote-cli.yml
│       ├── deploy-redis-cli.yml
│       ├── deploy-worker-cli.yml
│       ├── deploy-database-cli.yml
│       ├── deploy-result-cli.yml
│       ├── deploy-monitoring.yml
│       ├── setup-cloudwatch.yml
│       ├── deploy-app-metrics.yml
│       ├── test-connectivity.yml
│       ├── check-logs.yml
│       └── stop-all.yml
│
├── monitoring/             # Demo scripts
│   ├── quick-stress.sh
│   ├── vote-cats.sh
│   ├── vote-dogs.sh
│   └── reset-db-simple.sh
│
└── docs/                   # Documentation
    ├── ANSIBLE_EXPLAINED.md
    └── ANSIBLE_CONTROL_NODE.md  ⬅️ This file
```

---

## 🎯 Why Your Laptop is the Control Node

### Advantages:

1. **Security**
   - SSH keys stay on your laptop
   - No credentials stored in AWS
   - Full control over who can deploy

2. **Flexibility**
   - Run from anywhere (home, office, cafe)
   - No need for dedicated jump server
   - Easy to test changes locally

3. **Cost**
   - No additional AWS instance needed
   - No 24/7 running control server
   - Only pay for 3 application instances

4. **Simplicity**
   - No extra infrastructure to manage
   - Direct connection from development machine
   - Easy debugging and troubleshooting

### Alternative (Not Used in This Project):

Some teams run Ansible control node on:
- **Jenkins server** (CI/CD pipeline)
- **Dedicated bastion host** (always-on in AWS)
- **GitLab Runner** (automation)

But for this project: **Your laptop is perfect!** ✅

---

## 🔐 SSH Key Management

### Where Keys Live:

**On Control Node (Your Laptop):**
```bash
~/.ssh/martin-ap-northeast-2-key.pem

# Permissions must be 600 (read-only by you)
chmod 600 ~/.ssh/martin-ap-northeast-2-key.pem
```

**Referenced in Inventory:**
```yaml
ansible_ssh_private_key_file: ~/.ssh/martin-ap-northeast-2-key.pem
```

**NOT on AWS instances!**
- Frontend has its own key pair
- Backend and Database use same key
- Ansible uses your local key to authenticate

---

## 🎓 Testing the Control Node

### Verify Ansible Installation:
```bash
ansible --version
```

### Test Connectivity to All Hosts:
```bash
cd /home/marty/ironhack/project_multistack_devops_app/ansible
ansible all -i inventory/hosts.yml -m ping
```

**Expected output:**
```
frontend-instance | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
backend-instance | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
db-instance | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Run Ad-Hoc Command:
```bash
# Check uptime on all instances
ansible all -i inventory/hosts.yml -m command -a "uptime"

# Check Docker containers on backend
ansible backend -i inventory/hosts.yml -m command -a "docker ps"

# Check disk space on database
ansible database -i inventory/hosts.yml -m command -a "df -h"
```

---

## 🎤 Talking Points for Presentation

> "The Ansible control node is **my laptop** - not a server in AWS. This is Ansible's agentless architecture.
>
> I run `ansible-playbook` from my local machine, and Ansible SSH's to all 3 instances in parallel. For the private instances, it automatically uses the frontend as a jump host.
>
> No additional infrastructure needed. No agents to install. Just SSH, which we already have.
>
> This is one reason why Ansible is so popular - it's simple and secure. All credentials stay on my laptop, and I maintain full control over deployments."

---

## 📊 Control Node vs Managed Nodes

| Aspect | Control Node (Your Laptop) | Managed Nodes (AWS) |
|--------|---------------------------|---------------------|
| **Ansible Installed** | ✅ Yes | ❌ No |
| **Python** | ✅ Yes (any version) | ✅ Yes (comes with Ubuntu) |
| **SSH Client** | ✅ Yes | N/A |
| **SSH Server** | N/A | ✅ Yes |
| **Playbooks** | ✅ Stored here | ❌ Not needed |
| **Inventory** | ✅ Defined here | ❌ Not needed |
| **SSH Keys** | ✅ Private key here | ✅ Public key in authorized_keys |
| **Agents** | N/A | ❌ None! (agentless) |

---

## 🔄 Workflow Summary

```
┌─────────────────────────────────────────────────────────┐
│  1. You write playbook on laptop                        │
│  2. You run: ansible-playbook ...                       │
│  3. Ansible reads inventory (which servers?)            │
│  4. Ansible SSH's to servers (parallel)                 │
│  5. Ansible executes tasks (Docker commands)            │
│  6. Ansible collects results                            │
│  7. Ansible displays summary on your laptop             │
└─────────────────────────────────────────────────────────┘

Your laptop = Command center 🎮
AWS instances = Execution targets 🎯
```

---

## 🚨 Important Security Notes

### ✅ Good Practices (Used in This Project):

1. **SSH keys never leave your laptop**
   - Private key: `~/.ssh/*.pem`
   - Only public key on AWS

2. **Bastion host for private instances**
   - Frontend acts as jump host
   - Backend/Database not directly accessible

3. **No hardcoded passwords**
   - All credentials in variables
   - Can use Ansible Vault for secrets

4. **SSH security options**
   - `StrictHostKeyChecking=no` (for demo convenience)
   - In production: use `yes` and manage known_hosts

### ❌ Anti-Patterns (Avoided):

1. ❌ Storing SSH keys on AWS instances
2. ❌ Using same key for all servers
3. ❌ Hardcoding passwords in playbooks
4. ❌ Running Ansible as root unnecessarily

---

## 🎯 Summary

**Control Node Location:** Your laptop (`Nimzowitsch`)

**Why:**
- Security (keys stay with you)
- Simplicity (no extra infrastructure)
- Flexibility (run from anywhere)

**How it works:**
- Ansible uses SSH to connect to AWS instances
- ProxyJump for private instances
- Agentless (no software on AWS instances)
- Parallel execution

**Key insight:** Ansible turns your laptop into a powerful deployment control center that can manage hundreds of servers with simple YAML files and SSH! 🚀
