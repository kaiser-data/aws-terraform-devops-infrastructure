# Ansible Galaxy Roles - NOT Used in This Project

## 🎯 Quick Answer: NO

**This project does NOT use any Ansible Galaxy roles.**

---

## 📋 Evidence

### 1. No Roles Directory
```bash
$ ls ansible/
ansible.cfg
group_vars/
inventory/
playbooks/          # ✅ Just playbooks
README.md
```

❌ **No `roles/` directory**

---

### 2. No Galaxy Requirements File
```bash
$ find ansible/ -name "requirements.yml"
# No results
```

❌ **No `requirements.yml` file** (would list Galaxy roles to install)

---

### 3. Playbooks Use Only Tasks, Not Roles
```bash
$ grep -r "roles:" ansible/playbooks/
# No results
```

All playbooks use direct `tasks:` sections, not `roles:` sections.

---

### 4. Only Built-in Modules Used

**Modules in this project:**
- `ansible.builtin.command` - Run shell commands
- `ansible.builtin.shell` - Run shell scripts
- `ansible.builtin.apt` - Install packages
- `ansible.builtin.copy` - Copy files
- `ansible.builtin.file` - Manage files/directories
- `ansible.builtin.pip` - Install Python packages
- `ansible.builtin.debug` - Print messages
- `ansible.builtin.wait_for` - Wait for conditions

**All are core Ansible modules!** No community collections, no Galaxy roles.

---

## 🤔 What Are Ansible Galaxy Roles?

**Ansible Galaxy** is a repository of pre-built, reusable Ansible roles.

### Example Galaxy Roles:

```yaml
# requirements.yml
---
- name: geerlingguy.docker
  version: 4.1.2

- name: geerlingguy.postgresql
  version: 3.2.0

- name: ansible-community.mongodb
  version: 1.2.0
```

### How They Would Be Used:

```yaml
# playbook.yml
---
- name: Deploy database
  hosts: database
  roles:
    - geerlingguy.postgresql    # Pre-built role from Galaxy
```

**Benefits of Galaxy roles:**
- ✅ Pre-written, tested code
- ✅ Best practices included
- ✅ Community maintained
- ✅ Saves development time

**Downsides:**
- ❌ External dependency
- ❌ Less control
- ❌ Need to learn role variables
- ❌ May include features you don't need

---

## 🎯 Why This Project Doesn't Use Galaxy Roles

### 1. **Simplicity**
The project is straightforward enough that custom playbooks are simpler than learning and configuring Galaxy roles.

```yaml
# Our approach (direct tasks):
- name: Install Docker
  ansible.builtin.apt:
    name: docker.io
    state: present

# Galaxy role approach (more abstraction):
- name: Install Docker
  roles:
    - role: geerlingguy.docker
      docker_edition: 'ce'
      docker_package: "docker-ce"
      docker_users:
        - ubuntu
```

**Our way:** 5 lines, easy to understand
**Galaxy role:** Need to read role docs, understand variables

---

### 2. **Docker CLI Approach (Problem #2!)**

Remember: **Docker SDK totally failed** (Problem #2 from your presentation).

Many Galaxy roles use `community.docker` modules (the SDK):
```yaml
# Galaxy roles often use Docker SDK modules:
- name: Run container
  community.docker.docker_container:  # ❌ This failed!
    name: redis
    image: redis:alpine
```

**Our solution:** Use Docker CLI directly
```yaml
- name: Deploy Redis
  ansible.builtin.command:
    cmd: docker run -d --name redis redis:alpine  # ✅ Works!
```

**This is the "slim path in DevOps"** - don't add complexity when simple solutions work!

---

### 3. **Learning & Presentation Value**

For your Ironhack project:
- ✅ **Transparent:** You can see exactly what every task does
- ✅ **Educational:** Shows how Ansible works from basics
- ✅ **Debuggable:** Easy to troubleshoot and modify
- ✅ **Presentable:** Can explain every line of code

**With Galaxy roles:**
- ❌ "Magic" happening inside roles
- ❌ Harder to explain: "This role does everything"
- ❌ Less impressive: "I just used someone else's code"

---

### 4. **No Heavy Abstraction Needed**

**When to use Galaxy roles:**
- Complex multi-step setups (Kubernetes cluster, Elasticsearch stack)
- Need to support multiple OS distributions
- Reusing across many projects
- Enterprise standardization

**This project's needs:**
- Simple Docker deployments
- Single OS (Ubuntu)
- Specific to this architecture
- Learning project

**Verdict:** Custom playbooks are the right choice! ✅

---

## 📊 Comparison

| Aspect | Galaxy Roles | Custom Playbooks (This Project) |
|--------|-------------|----------------------------------|
| **Complexity** | High (role variables, dependencies) | Low (direct tasks) |
| **Control** | Limited (role internals) | Full (you write everything) |
| **Transparency** | Low (abstracted) | High (explicit) |
| **Dependencies** | External (Galaxy) | None (self-contained) |
| **Learning Value** | Low (using others' code) | High (understanding fundamentals) |
| **Customization** | Limited (override vars) | Unlimited (modify anything) |
| **Maintenance** | Update roles when needed | Update your own playbooks |
| **Best For** | Enterprise, complex setups | Learning, simple deployments |

---

## 🎓 When SHOULD You Use Galaxy Roles?

### Good Use Cases:

#### 1. **Complex Software Stacks**
```yaml
# Installing Kubernetes is complex:
- name: kubernetes-cluster
  roles:
    - role: geerlingguy.kubernetes
      kubernetes_version: '1.25'
      kubernetes_pod_network_cidr: '10.244.0.0/16'
```

Better than writing 500 lines of tasks yourself!

---

#### 2. **Multi-OS Support**
```yaml
# Role handles Ubuntu, CentOS, RHEL automatically:
- name: Install Docker
  roles:
    - geerlingguy.docker
  # Role detects OS and uses appropriate package manager
```

---

#### 3. **Enterprise Standardization**
```yaml
# Company-wide standard PostgreSQL setup:
- name: database-servers
  roles:
    - company.postgresql-enterprise
      pg_version: 14
      backup_enabled: true
      monitoring_enabled: true
```

---

#### 4. **Reusable Across Projects**

If you're deploying similar infrastructure for multiple clients, roles make sense.

---

## 🎤 Talking Points for Presentation

### If Asked: "Why didn't you use Ansible Galaxy roles?"

> "Great question! I considered using Galaxy roles like `geerlingguy.docker`, but decided against it for several reasons:
>
> **1. Simplicity** - Custom playbooks are more transparent. You can see exactly what each task does, which is important for a learning project.
>
> **2. Docker SDK Problem** - Many Galaxy roles use `community.docker` modules, which totally failed in my project (Problem #2). Using Docker CLI directly is more reliable.
>
> **3. Educational Value** - Writing custom playbooks taught me how Ansible actually works, rather than just using pre-built abstractions.
>
> **4. Right-Sized Solution** - For 12 playbooks and simple Docker deployments, Galaxy roles would add unnecessary complexity.
>
> In production, I'd consider Galaxy roles for complex setups like Kubernetes clusters or multi-OS support, but for this project, custom playbooks are the pragmatic choice."

---

## 🚀 What This Project Uses Instead

### Project Structure (No Roles):

```
ansible/
├── inventory/
│   └── hosts.yml           # Server definitions
├── group_vars/
│   └── all.yml             # Variables (IPs, ports, images)
├── playbooks/
│   ├── install-docker.yml  # ⬅️ Direct tasks, no roles
│   ├── deploy-vote-cli.yml
│   ├── deploy-redis-cli.yml
│   ├── deploy-worker-cli.yml
│   ├── deploy-database-cli.yml
│   ├── deploy-result-cli.yml
│   ├── deploy-monitoring.yml
│   ├── setup-cloudwatch.yml
│   ├── deploy-app-metrics.yml
│   ├── test-connectivity.yml
│   ├── check-logs.yml
│   └── stop-all.yml
└── ansible.cfg             # Configuration
```

**Key insight:** Flat structure with playbooks containing tasks directly.

---

### Playbook Example (No Roles):

```yaml
---
- name: Deploy Redis
  hosts: backend
  become: no
  gather_facts: yes
  vars_files:
    - ../group_vars/all.yml

  tasks:                          # ⬅️ Direct tasks, not roles!
    - name: Pull Redis image
      ansible.builtin.command:
        cmd: docker pull redis:alpine

    - name: Stop existing Redis
      ansible.builtin.command:
        cmd: docker stop redis
      failed_when: false

    - name: Deploy Redis
      ansible.builtin.command:
        cmd: >
          docker run -d
          --name redis
          --restart always
          -p 6379:6379
          redis:alpine
```

**Clean, simple, transparent!** ✅

---

## 📚 Learning More About Galaxy

### If You Want to Explore Galaxy:

**Browse roles:**
```bash
# Search for Docker roles
ansible-galaxy search docker

# Search for PostgreSQL roles
ansible-galaxy search postgresql
```

**Install a role:**
```bash
# Install specific role
ansible-galaxy install geerlingguy.docker

# Install from requirements.yml
ansible-galaxy install -r requirements.yml
```

**Popular role authors:**
- `geerlingguy.*` - Jeff Geerling (very popular, well-maintained)
- `ansible-community.*` - Official Ansible community
- `robertdebock.*` - Robert de Bock (lots of roles)

**Galaxy website:** https://galaxy.ansible.com/

---

## 🎯 Summary

**Ansible Galaxy roles in this project:** ❌ **NONE**

**Why:**
1. Simplicity and transparency
2. Avoiding Docker SDK issues (Problem #2)
3. Educational value (learning fundamentals)
4. Right-sized solution (no over-engineering)

**When to use Galaxy roles:**
- Complex software stacks (Kubernetes, ELK)
- Multi-OS support requirements
- Enterprise standardization
- Reusable across many projects

**This project's approach:**
- ✅ Custom playbooks with direct tasks
- ✅ `ansible.builtin.*` modules only
- ✅ Docker CLI for reliability
- ✅ Transparent, maintainable code

**The slim path in DevOps:** Use the simplest solution that works! 🚀
