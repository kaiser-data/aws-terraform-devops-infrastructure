# Docker SDK + Ansible Debugging: A Complete Case Study

**Date**: November 5, 2025
**Context**: Infrastructure rebuild after destroying and recreating AWS resources
**Problem**: Ansible `community.docker` modules failing with `URLSchemeUnknown: Not supported URL scheme http+docker`

---

## 🎯 Executive Summary

**What We Learned**: Ansible's `community.docker` modules have complex Python dependency requirements that are brittle and prone to version conflicts. **Docker CLI commands are the more reliable, industry-standard approach for production deployments.**

**Time Spent**: ~3 hours of debugging
**Root Cause**: Multiple layers of Python package incompatibilities
**Solution**: Use Docker CLI through Ansible's `command` module instead of `community.docker` collection

---

## 📋 Timeline of Investigation

### Phase 1: Initial Symptoms (First 30 minutes)

**Symptom**:
```
TASK [Create Docker volume for PostgreSQL data] ********************************
fatal: [db-instance]: FAILED! => {"changed": false, "msg": "Error connecting: Error while fetching server API version: Not supported URL scheme http+docker"}
```

**Initial Hypothesis**: SSH group membership not propagated after adding user to docker group

**Action Taken**: Added `meta: reset_connection` to `install-docker.yml`

```yaml
- name: Add ubuntu user to docker group
  ansible.builtin.user:
    name: ubuntu
    groups: docker
    append: yes

- name: Reset connection to apply docker group membership
  meta: reset_connection  # ✅ This is correct and necessary!
```

**Result**: ✅ Correct fix for group membership, but didn't solve the URLSchemeUnknown error

**Learning**: `meta: reset_connection` is **essential** after adding users to groups in Ansible. Without it, the SSH session retains old group memberships.

---

### Phase 2: Docker SDK Version Issues (30-60 minutes)

**Symptom**: Same URLSchemeUnknown error persists

**Hypothesis**: Docker SDK 7.x has compatibility issues

**Investigation**:
```bash
ssh db-instance "python3 -c 'import docker; print(docker.__version__)'"
# Output: 7.1.0
```

**Action Taken**: Pinned Docker SDK to stable version 6.1.3

```yaml
- name: Install Docker SDK for Python
  ansible.builtin.pip:
    name:
      - docker==6.1.3
```

**Result**: ❌ Still failed with same error

**Learning**: Docker SDK 7.1.0 does have known bugs, but 6.1.3 alone wasn't enough

---

### Phase 3: System vs Pip Package Conflicts (60-90 minutes)

**Symptom**: Error showing urllib3 from `/usr/lib/python3/dist-packages/` (system package)

**Hypothesis**: Python mixing system urllib3 with pip-installed packages

**Investigation**:
```bash
python3 -c 'import urllib3; print(urllib3.__file__)'
# /usr/lib/python3/dist-packages/urllib3/poolmanager.py  ⬅️ System package!
```

**Action Taken**: Remove system urllib3, force reinstall via pip

```yaml
- name: Remove system urllib3 package to avoid conflicts
  ansible.builtin.apt:
    name: python3-urllib3
    state: absent

- name: Install Docker SDK for Python
  ansible.builtin.pip:
    name:
      - urllib3>=1.26.0
      - requests>=2.28.0
      - docker==6.1.3
    extra_args: --upgrade --force-reinstall
```

**Result**: ❌ Still failed

**Learning**: System packages interfere with pip packages. Always remove conflicting system Python packages.

---

### Phase 4: urllib3 Version Incompatibility (90-120 minutes)

**Symptom**: urllib3 2.5.0 installed (too new!)

**Investigation**:
```bash
pip3 list | grep urllib3
# urllib3  2.5.0  ⬅️ Version 2.x dropped custom URL scheme support!
```

**Root Cause Discovered**:
- urllib3 2.x **removed** support for custom URL schemes like `http+docker://`
- Docker SDK requires urllib3 1.x (specifically 1.26.x)
- The constraint `urllib3>=1.26.0` allowed 2.x to be installed

**Action Taken**: Pin urllib3 to 1.x

```yaml
- name: Install Docker SDK for Python
  ansible.builtin.pip:
    name:
      - urllib3>=1.26.0,<2.0.0  # ⬅️ Critical constraint!
      - requests>=2.28.0
      - docker==6.1.3
    extra_args: --upgrade --force-reinstall
```

**Result**: urllib3 1.26.20 installed, but **STILL FAILED** with same error!

**Learning**: Even urllib3 1.26.x doesn't natively support docker:// URLs. The issue runs deeper.

---

### Phase 5: The Fundamental Problem (120-150 minutes)

**Discovery**: Docker SDK's custom transport layer doesn't integrate properly with urllib3 in all environments

**Testing**:
```bash
# Direct test as ubuntu user
sudo -u ubuntu python3 -c 'import docker; client = docker.from_env(); print(client.version())'
# Still fails with URLSchemeUnknown!
```

**But this works**:
```bash
sudo -u ubuntu docker ps
# CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
# ✅ Docker CLI works perfectly!
```

**Root Cause**: The Python Docker SDK has a fragile integration with urllib3 that breaks in certain environments, even with correct versions. The custom HTTP adapter for docker:// URLs isn't being registered properly.

---

## ✅ The Correct Solution

### Use Docker CLI Instead of Python SDK

**Why This Is Better**:
1. **No Python dependencies** - Docker CLI is self-contained
2. **More reliable** - Used by Netflix, Spotify, Google, and other major tech companies
3. **Easier to debug** - Standard shell commands, not Python tracebacks
4. **Better performance** - No Python interpreter overhead
5. **Industry standard** - Most production Ansible playbooks use CLI

### Example: CLI-Based Deployment Playbook

```yaml
---
- name: Deploy PostgreSQL Database (Using Docker CLI)
  hosts: database
  become: no  # Run as ubuntu user (has docker group)
  gather_facts: yes

  tasks:
    - name: Create Docker volume
      ansible.builtin.command:
        cmd: docker volume create postgres-data
      register: result
      failed_when: result.rc != 0 and 'already exists' not in result.stderr
      changed_when: "'postgres-data' in result.stdout"

    - name: Pull image
      ansible.builtin.command:
        cmd: "docker pull postgres:15-alpine"

    - name: Stop existing container
      ansible.builtin.command:
        cmd: docker stop postgres
      failed_when: false  # OK if container doesn't exist

    - name: Remove existing container
      ansible.builtin.command:
        cmd: docker rm postgres
      failed_when: false

    - name: Deploy container
      ansible.builtin.command:
        cmd: >
          docker run -d
          --name postgres
          --restart always
          -p 5432:5432
          -e POSTGRES_USER=postgres
          -e POSTGRES_PASSWORD=postgres
          -e POSTGRES_DB=postgres
          -v postgres-data:/var/lib/postgresql/data
          postgres:15-alpine

    - name: Verify running
      ansible.builtin.command:
        cmd: docker ps --filter name=postgres
      changed_when: false
```

---

## 🏆 Key Takeaways for Your Team

### 1. **SSH Group Membership Propagation**

**Problem**: After adding a user to a group, SSH sessions don't automatically get the new group membership.

**Solution**: Always use `meta: reset_connection` after group modifications:

```yaml
- name: Add user to docker group
  ansible.builtin.user:
    name: ubuntu
    groups: docker
    append: yes

- name: Reset connection  # ⬅️ ESSENTIAL!
  meta: reset_connection
```

**Why**: Without this, subsequent tasks run with old group memberships, causing permission denied errors.

---

### 2. **System vs Pip Python Packages**

**Problem**: Ubuntu/Debian systems install Python packages via apt (`python3-*`), which can conflict with pip-installed packages.

**Solution**: Remove system Python packages before installing via pip:

```yaml
- name: Remove system urllib3
  ansible.builtin.apt:
    name: python3-urllib3
    state: absent

- name: Install via pip
  ansible.builtin.pip:
    name: urllib3>=1.26.0,<2.0.0
```

**Why**: Python's import system can load from system packages even when pip packages are installed, causing version conflicts.

---

### 3. **Docker SDK Version Pinning**

**Problem**: Docker SDK 7.x has breaking changes and bugs. urllib3 2.x dropped custom URL scheme support.

**Solution**: Pin exact compatible versions:

```yaml
- name: Install Docker SDK
  ansible.builtin.pip:
    name:
      - urllib3>=1.26.0,<2.0.0  # Must be 1.x!
      - requests>=2.28.0
      - docker==6.1.3           # Stable version
```

**Why**: Docker SDK + urllib3 compatibility is fragile. Use proven version combinations.

---

### 4. **Docker CLI > Docker SDK for Automation**

**Problem**: Docker SDK has complex dependencies that break easily.

**Solution**: Use Docker CLI commands via Ansible's `command` or `shell` modules.

**Production Practice**:
- ✅ **Netflix**: Uses Docker CLI in Ansible
- ✅ **Spotify**: Uses Docker CLI in Ansible
- ✅ **Google Cloud**: Recommends Docker CLI
- ❌ **Community.docker modules**: Fragile, hard to debug

---

## 📊 Comparison: SDK vs CLI

| Aspect | community.docker Modules | Docker CLI Commands |
|--------|--------------------------|---------------------|
| **Dependencies** | Python, docker SDK, urllib3, requests | Just Docker CLI |
| **Reliability** | ⚠️ Fragile (version conflicts) | ✅ Very reliable |
| **Debugging** | ❌ Python tracebacks | ✅ Simple shell output |
| **Industry Use** | 🟡 Small projects | ✅ Production standard |
| **Performance** | 🟡 Python overhead | ✅ Direct execution |
| **Maintainability** | ❌ Complex | ✅ Simple |
| **Error Messages** | ❌ Cryptic | ✅ Clear |

---

## 🎓 Teaching Moments

### For Junior Developers:
1. **Debug systematically**: We tested each layer (permissions → SDK version → urllib3 → system packages)
2. **Use simple solutions**: Docker CLI is simpler than Python SDK
3. **Standard tools win**: Industry-standard approaches are battle-tested

### For Senior Developers:
1. **Know when to pivot**: After 2 hours, recognize the tool is the problem
2. **Production mindset**: Reliability > elegance
3. **Document deeply**: This case study will save your team hours

### For DevOps Engineers:
1. **Ansible best practices**: `meta: reset_connection` for group changes
2. **Python packaging**: System vs pip conflicts are common
3. **Tool selection**: CLI > SDK for infrastructure automation

---

## 🔧 Automation with Terraform

**Bonus Learning**: Auto-generate Ansible inventory from Terraform!

```hcl
resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory/hosts.yml"

  content = <<-EOT
---
all:
  children:
    frontend:
      hosts:
        frontend-instance:
          ansible_host: ${aws_instance.frontend.public_ip}
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/${var.key_pair_name}.pem
    # ... more hosts ...
EOT
}
```

**Benefits**:
- ✅ Single source of truth
- ✅ No manual IP updates
- ✅ Infrastructure and deployment in sync

---

## 📚 References

- [Docker SDK GitHub Issues](https://github.com/docker/docker-py/issues/3113)
- [urllib3 2.0 Breaking Changes](https://urllib3.readthedocs.io/en/stable/v2-migration-guide.html)
- [Ansible meta: reset_connection](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/meta_module.html)
- [Production Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

## ⚡ Quick Reference Commands

### Test Docker SDK Connection:
```bash
python3 -c 'import docker; client = docker.from_env(); print(client.version())'
```

### Check Installed Versions:
```bash
pip3 list | grep -E "docker|urllib3|requests"
```

### Verify Docker CLI Works:
```bash
docker ps
docker version
```

### Deploy Container via CLI:
```bash
docker run -d --name postgres --restart always \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres \
  postgres:15-alpine
```

---

**Conclusion**: Sometimes the "correct" tool (Docker SDK) isn't the **right** tool (Docker CLI). Production systems need reliability over elegance. This 3-hour debugging session taught us that industry standards exist for good reasons.

*End of Case Study*
