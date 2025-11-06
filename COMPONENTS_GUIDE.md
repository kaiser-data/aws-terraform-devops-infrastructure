# Complete Components & Architecture Guide

## Table of Contents
1. [Infrastructure Overview](#infrastructure-overview)
2. [AWS Components](#aws-components)
3. [Application Components](#application-components)
4. [Monitoring Stack](#monitoring-stack)
5. [Data Flow](#data-flow)
6. [Testing & Access](#testing--access)

---

## Infrastructure Overview

### Architecture Diagram
```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Cloud (ap-northeast-2)                   │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ Terraform State Management (Backend)                           │ │
│  │                                                                 │ │
│  │  ┏━━━━━━━━━━━━━━━━━━━━━┓      ┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓   │ │
│  │  ┃ S3 Bucket            ┃      ┃ DynamoDB Table           ┃   │ │
│  │  ┃ flux-capacitor-state ┃◄────►┃ time-lock                ┃   │ │
│  │  ┃ - Versioned          ┃      ┃ - State Locking          ┃   │ │
│  │  ┃ - Encrypted (AES256) ┃      ┃ - PAY_PER_REQUEST        ┃   │ │
│  │  ┗━━━━━━━━━━━━━━━━━━━━━┛      ┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛   │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ VPC: time-circuit-vpc (10.0.0.0/16)                            │ │
│  │                                                                 │ │
│  │  ┌──────────────────────────────┐  ┌───────────────────────┐  │ │
│  │  │ Public Subnet (10.0.1.0/24)  │  │ Private Subnet        │  │ │
│  │  │ AZ: ap-northeast-2a          │  │ (10.0.2.0/24)         │  │ │
│  │  │                              │  │ AZ: ap-northeast-2a   │  │ │
│  │  │  ┏━━━━━━━━━━━━━━━━━━━━━━━┓  │  │  ┏━━━━━━━━━━━━━━━┓  │  │ │
│  │  │  ┃ Frontend Instance     ┃  │  │  ┃ Backend       ┃  │  │ │
│  │  │  ┃ clocktower-frontend   ┃  │  │  ┃ doc-lab       ┃  │  │ │
│  │  │  ┃ Public: 3.36.116.222  ┃  │  │  ┃ 10.0.2.75     ┃  │  │ │
│  │  │  ┃ Private: 10.0.1.x     ┃◄─┼──┼──┃               ┃  │  │ │
│  │  │  ┃                       ┃  │  │  ┃ ┌───────────┐ ┃  │  │ │
│  │  │  ┃ Containers:           ┃  │  │  ┃ │Redis      │ ┃  │  │ │
│  │  │  ┃ • Vote App (:80)      ┃──┼──┼─►┃ │:6379      │ ┃  │  │ │
│  │  │  ┃ • Result App (:5001)  ┃  │  │  ┃ └───────────┘ ┃  │  │ │
│  │  │  ┃ • Prometheus (:9090)  ┃  │  │  ┃ ┌───────────┐ ┃  │  │ │
│  │  │  ┃ • Grafana (:3000)     ┃  │  │  ┃ │Worker     │ ┃  │  │ │
│  │  │  ┃ • Node Exporter       ┃  │  │  ┃ │(.NET)     │ ┃  │  │ │
│  │  │  ┗━━━━━━━━━━━━━━━━━━━━━━━┛  │  │  ┗━━━━━━━━━━━━━━━┛  │  │ │
│  │  │             │                │  │         │            │  │ │
│  │  │             │                │  │         │            │  │ │
│  │  │      ┌──────▼──────┐         │  │         │            │  │ │
│  │  │      │   IGW       │         │  │         │            │  │ │
│  │  │      │ Internet    │         │  │         ▼            │  │ │
│  │  │      │ Gateway     │         │  │  ┏━━━━━━━━━━━━━━━┓  │  │ │
│  │  │      └─────────────┘         │  │  ┃ Database      ┃  │  │ │
│  │  │                              │  │  ┃ timeline-db   ┃  │  │ │
│  │  │                              │  │  ┃ 10.0.2.115    ┃  │  │ │
│  │  └──────────────────────────────┘  │  ┃               ┃  │  │ │
│  │                                     │  ┃ ┌───────────┐ ┃  │  │ │
│  │                                     │  ┃ │PostgreSQL │ ┃  │  │ │
│  │  ┌──────────────────────────────┐  │  ┃ │:5432      │ ┃  │  │ │
│  │  │     NAT Gateway              │◄─┼──┃ └───────────┘ ┃  │  │ │
│  │  │     (Private → Internet)     │  │  ┗━━━━━━━━━━━━━━━┛  │  │ │
│  │  └──────────────────────────────┘  └───────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘

Internet Users → Vote/Result Apps → Redis → Worker → PostgreSQL
```

---

## AWS Components

### 1. Terraform State Backend

#### S3 Bucket: `flux-capacitor-state`
**Purpose**: Store Terraform state files securely

**Configuration**:
- **Name Pattern**: `{project_name}-terraform-state-{account_id}`
- **Versioning**: Enabled (allows state rollback)
- **Encryption**: AES256 server-side encryption
- **Public Access**: Blocked (all 4 settings enabled)
- **Lifecycle**: Old versions deleted after 90 days
- **Protection**: `prevent_destroy = true`

**Location**: `terraform/terraform-backend/main.tf:1-62`

**Benefits**:
- ✅ Team collaboration (shared state)
- ✅ State history (version tracking)
- ✅ Security (encryption at rest)
- ✅ Disaster recovery (versioned backups)

#### DynamoDB Table: `time-lock`
**Purpose**: Prevent concurrent Terraform operations (state locking)

**Configuration**:
- **Name Pattern**: `{project_name}-terraform-locks`
- **Billing**: PAY_PER_REQUEST (cost-efficient)
- **Hash Key**: `LockID` (string)
- **Point-in-Time Recovery**: Enabled
- **Protection**: `prevent_destroy = true`

**Location**: `terraform/terraform-backend/main.tf:64-90`

**How it Works**:
1. Terraform acquires lock before state modification
2. Lock stored in DynamoDB with unique `LockID`
3. Other operations wait until lock released
4. Prevents state corruption from simultaneous changes

**Benefits**:
- ✅ Prevents race conditions
- ✅ Team safety (one person deploys at a time)
- ✅ State integrity protection
- ✅ Low cost (~$0.01/month)

---

### 2. Network Infrastructure

#### VPC: `time-circuit-vpc`
- **CIDR**: 10.0.0.0/16 (65,536 IP addresses)
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled
- **Region**: ap-northeast-2 (Seoul)

#### Subnets

**Public Subnet**: `townsquare-public`
- **CIDR**: 10.0.1.0/24 (256 IPs)
- **AZ**: ap-northeast-2a
- **Public IPs**: Auto-assigned
- **Purpose**: Internet-facing services
- **Hosts**: Frontend instance

**Private Subnet**: `lab-private`
- **CIDR**: 10.0.2.0/24 (256 IPs)
- **AZ**: ap-northeast-2a
- **Public IPs**: None
- **Purpose**: Internal services
- **Hosts**: Backend + Database instances

#### Gateways

**Internet Gateway**: `flux-gateway`
- **Purpose**: Public subnet internet access
- **Route**: 0.0.0.0/0 → IGW
- **Attached to**: Public subnet route table

**NAT Gateway**
- **Purpose**: Private subnet outbound internet
- **Elastic IP**: Allocated automatically
- **Use Cases**:
  - Package updates (apt, yum)
  - Docker image pulls
  - OS security patches
- **Important**: Does NOT allow inbound internet traffic

---

### 3. EC2 Instances

#### Instance Type: t3.micro
- **vCPU**: 2
- **RAM**: 1 GB
- **Network**: Up to 5 Gbps
- **Cost**: ~$0.0104/hour (~$7.50/month per instance)
- **Total Monthly Cost**: ~$22.50 for 3 instances

#### Frontend Instance: `clocktower-voting-frontend`
**Role**: Public-facing application server + Bastion host

**Network**:
- Public IP: 3.36.116.222
- Private IP: 10.0.1.x (dynamic)
- Subnet: Public (10.0.1.0/24)

**Security Group**: `bttf-frontend-sg`
- SSH (22): Your IP only
- HTTP (80): 0.0.0.0/0 (Vote app)
- 5001: 0.0.0.0/0 (Result app)
- 9090: 0.0.0.0/0 (Prometheus - should restrict)
- 3000: 0.0.0.0/0 (Grafana - should restrict)
- 9100: 0.0.0.0/0 (Node Exporter - should restrict)
- Egress: All traffic allowed

**Containers**:
1. **vote** - Python Flask voting app (port 80)
2. **result** - Node.js results display (port 5001)
3. **prometheus** - Metrics collection (port 9090) *[if deployed]*
4. **grafana** - Metrics visualization (port 3000) *[if deployed]*
5. **node-exporter** - System metrics (port 9100) *[if deployed]*

**Additional Roles**:
- SSH Bastion for private instances
- Monitoring server
- Application gateway

#### Backend Instance: `doc-lab-processor`
**Role**: Message queue + Vote processor

**Network**:
- Public IP: None
- Private IP: 10.0.2.75
- Subnet: Private (10.0.2.0/24)

**Security Group**: `bttf-backend-sg`
- SSH (22): Frontend SG only
- Redis (6379): Frontend SG only
- Egress: All traffic (for package updates via NAT)

**Containers**:
1. **redis** - In-memory queue (port 6379)
   - Image: redis:alpine
   - Volume: redis-data:/data
   - Persistence: appendonly mode

2. **worker** - .NET vote processor
   - Image: dockersamples/examplevotingapp_worker
   - Connects to: Redis + PostgreSQL
   - Function: Reads votes from Redis → Writes to PostgreSQL

**SSH Access**:
```bash
ssh -J frontend-instance backend-instance
# OR
ssh backend-instance  # (with ProxyJump in ~/.ssh/config)
```

#### Database Instance: `timeline-archive-db`
**Role**: Persistent data storage

**Network**:
- Public IP: None
- Private IP: 10.0.2.115
- Subnet: Private (10.0.2.0/24)

**Security Group**: `bttf-database-sg`
- SSH (22): Frontend SG only
- PostgreSQL (5432): Backend SG + Frontend SG
- Egress: All traffic (for package updates via NAT)

**Containers**:
1. **postgres** - PostgreSQL database (port 5432)
   - Image: postgres:15-alpine
   - Database: postgres
   - User: postgres
   - Password: postgres (⚠️ Change in production!)
   - Volume: postgres-data:/var/lib/postgresql/data

**SSH Access**:
```bash
ssh -J frontend-instance db-instance
# OR
ssh db-instance  # (with ProxyJump in ~/.ssh/config)
```

---

## Application Components

### Data Flow Architecture
```
┌──────────┐     ┌───────┐     ┌────────┐     ┌────────────┐
│  User    │────►│ Vote  │────►│ Redis  │────►│  Worker    │
│ Browser  │     │ App   │     │ Queue  │     │ (.NET)     │
└──────────┘     └───────┘     └───────┘     └──────┬─────┘
                     │                              │
                     │                              ▼
                     │                        ┌──────────┐
                     │                        │PostgreSQL│
                     │                        │ Database │
                     │                        └────┬─────┘
                     │                             │
                     │         ┌───────┐           │
                     └────────►│Result │◄──────────┘
                               │ App   │
                               └───────┘
```

### 1. Vote Application (Frontend)
**Technology**: Python + Flask
**Port**: 80
**Function**: User voting interface

**Features**:
- Vote between two options (Cats vs Dogs)
- Cookie-based voter identification
- Redis connectivity for vote storage
- Real-time vote submission

**Environment Variables**:
- `REDIS_HOST`: 10.0.2.75 (Backend private IP)
- `REDIS_PORT`: 6379
- `OPTION_A`: Cats
- `OPTION_B`: Dogs

**Code Location**: `apps/vote/app.py`

**Data Storage**:
1. Generates unique voter ID (64-bit random hex)
2. Stores voter ID in browser cookie
3. Writes vote to Redis: `SET voter_id vote`
4. Pushes vote to Redis list: `RPUSH votes {voter_id, vote}`

### 2. Redis (Backend)
**Technology**: Redis (in-memory data store)
**Port**: 6379
**Function**: Message queue and temporary vote storage

**Configuration**:
- Image: redis:alpine
- Persistence: AOF (append-only file) enabled
- Volume: redis-data:/data
- Health check: Healthy status

**Data Structures**:
- **Key-Value**: `voter_id → vote` (quick lookup)
- **List**: `votes` (FIFO queue for worker)

**Persistence**:
- Writes operations to appendonly.aof file
- Survives container restarts
- Automatic background save

### 3. Worker (Backend)
**Technology**: .NET (C#)
**Function**: Vote processor (Redis → PostgreSQL)

**Process Flow**:
1. Polls Redis list `votes` (blocking BLPOP)
2. Reads vote data: `{voter_id, vote}`
3. Writes to PostgreSQL `votes` table
4. Updates vote counts in database
5. Loops continuously

**Environment Variables**:
- `REDIS_HOST`: 10.0.2.75
- `REDIS_PORT`: 6379
- `POSTGRES_HOST`: 10.0.2.115
- `POSTGRES_PORT`: 5432
- `POSTGRES_USER`: postgres
- `POSTGRES_PASSWORD`: postgres
- `POSTGRES_DB`: postgres

**Why Separate Worker?**:
- Decouples web app from database
- Asynchronous vote processing
- Scales independently
- Fault tolerance (queue persists)

### 4. PostgreSQL (Database)
**Technology**: PostgreSQL 15
**Port**: 5432
**Function**: Persistent vote storage

**Configuration**:
- Image: postgres:15-alpine
- Volume: postgres-data:/var/lib/postgresql/data
- Health check: Healthy status

**Schema** (auto-created by worker):
```sql
CREATE TABLE votes (
    id SERIAL PRIMARY KEY,
    voter_id VARCHAR(64),
    vote VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Connections**:
- Worker: Writes votes
- Result app: Reads vote counts

### 5. Result Application (Frontend)
**Technology**: Node.js + Express + Socket.IO
**Port**: 5001
**Function**: Real-time vote results display

**Features**:
- Live vote count updates
- WebSocket connection (Socket.IO)
- Animated bar chart
- Responsive design

**Environment Variables**:
- `POSTGRES_HOST`: 10.0.2.115
- `POSTGRES_PORT`: 5432
- `POSTGRES_USER`: postgres
- `POSTGRES_PASSWORD`: postgres
- `POSTGRES_DB`: postgres

**Query**:
```sql
SELECT vote, COUNT(*) as count
FROM votes
GROUP BY vote;
```

**Real-time Updates**:
- Polls database every 1 second
- Emits updates via WebSocket
- Clients update without page refresh

---

## Monitoring Stack

### Architecture
```
┌──────────────┐     ┌────────────┐     ┌─────────┐
│ Node Exporter│────►│ Prometheus │────►│ Grafana │
│ (All nodes)  │     │ (Scraper)  │     │ (Display)│
└──────────────┘     └────────────┘     └─────────┘
```

### 1. Prometheus (Time-Series Database)
**Port**: 9090 (if deployed)
**Function**: Metrics collection and storage

**Configuration**: `monitoring/prometheus/prometheus.yml`

**Scrape Jobs**:
1. **prometheus**: Self-monitoring (localhost:9090)
2. **frontend-node**: Frontend system metrics (localhost:9100)
3. **backend-node**: Backend system metrics (10.0.2.75:9100)
4. **database-node**: Database system metrics (10.0.2.115:9100)

**Scrape Interval**: 15 seconds

**Metrics Collected**:
- CPU usage
- Memory usage
- Disk I/O
- Network traffic
- Container metrics
- System load

**Access**: http://3.36.116.222:9090

**Status**: ⚠️ Not currently deployed (configuration exists)

### 2. Grafana (Visualization)
**Port**: 3000 (if deployed)
**Function**: Metrics visualization and dashboards

**Configuration**: `monitoring/grafana/docker-compose.yml`

**Features**:
- Pre-configured Prometheus datasource
- Dashboard for infrastructure metrics
- Alerting capabilities
- User authentication

**Default Credentials** (if deployed):
- Username: admin
- Password: admin (change on first login)

**Access**: http://3.36.116.222:3000

**Status**: ⚠️ Not currently deployed (configuration exists)

### 3. Node Exporter
**Port**: 9100
**Function**: System metrics exporter

**Metrics Provided**:
- CPU: usage, load average, context switches
- Memory: used, free, cached, swap
- Disk: usage, I/O operations, read/write bytes
- Network: bytes sent/received, packets, errors
- System: uptime, file descriptors, processes

**Deployment**: Should be on all 3 instances

**Status**: ⚠️ Configuration exists in security groups, needs deployment

---

## Data Flow

### Complete Vote Journey
```
1. User clicks "Cats" in browser
   │
   ▼
2. Vote App (Flask) receives POST request
   │
   ├─ Generates/retrieves voter_id from cookie
   ├─ Connects to Redis (10.0.2.75:6379)
   │
   ▼
3. Redis stores vote
   │
   ├─ SET voter_id "Cats"           # Quick lookup
   ├─ RPUSH votes '{"voter_id":"abc123","vote":"Cats"}'  # Queue
   │
   ▼
4. Worker (.NET) polls Redis
   │
   ├─ BLPOP votes 0                 # Blocking pop
   ├─ Retrieves vote data
   │
   ▼
5. Worker writes to PostgreSQL (10.0.2.115:5432)
   │
   ├─ INSERT INTO votes (voter_id, vote, created_at)
   │   VALUES ('abc123', 'Cats', NOW())
   │
   ▼
6. Result App (Node.js) queries PostgreSQL
   │
   ├─ SELECT vote, COUNT(*) FROM votes GROUP BY vote
   ├─ Every 1 second via WebSocket
   │
   ▼
7. Browser displays updated results
   │
   └─ Cats: 42 votes | Dogs: 38 votes
```

### Network Communication Paths

**Public Traffic**:
- User → Frontend (3.36.116.222:80) - Vote submission
- User → Frontend (3.36.116.222:5001) - Results viewing

**Private Traffic** (within VPC):
- Frontend → Backend (10.0.2.75:6379) - Redis operations
- Frontend → Database (10.0.2.115:5432) - Result queries
- Backend Worker → Backend Redis (10.0.2.75:6379) - Vote retrieval
- Backend Worker → Database (10.0.2.115:5432) - Vote storage

**Outbound Traffic** (via NAT):
- All instances → Internet - Package updates, Docker pulls

**SSH Traffic**:
- Admin → Frontend (3.36.116.222:22) - Direct SSH
- Admin → Backend (via Frontend) - SSH ProxyJump
- Admin → Database (via Frontend) - SSH ProxyJump

---

## Testing & Access

### Quick Access URLs
```
Vote App:       http://3.36.116.222:80
Result App:     http://3.36.116.222:5001
Prometheus:     http://3.36.116.222:9090  (if deployed)
Grafana:        http://3.36.116.222:3000  (if deployed)
```

### SSH Access
```bash
# Direct (Frontend)
ssh frontend-instance

# Via Bastion (Backend)
ssh backend-instance

# Via Bastion (Database)
ssh db-instance
```

### Health Check Script
```bash
./testing-scripts/quick-test.sh
```

**Tests Performed**:
1. ✅ SSH connectivity (all 3 instances)
2. ✅ Docker installation verification
3. ✅ Container health status
4. ✅ Web application HTTP 200 checks
5. ✅ Redis connectivity (TCP 6379)
6. ✅ PostgreSQL connectivity (TCP 5432)

### Manual Testing

**Test Vote Flow**:
```bash
# 1. Cast a vote
curl -X POST http://3.36.116.222/vote -d "vote=a"

# 2. Check Redis (from frontend)
ssh frontend-instance
docker exec redis redis-cli LLEN votes

# 3. Check PostgreSQL (from database)
ssh db-instance
docker exec -it postgres psql -U postgres -c "SELECT vote, COUNT(*) FROM votes GROUP BY vote;"

# 4. View results
curl http://3.36.116.222:5001
```

**Check Container Logs**:
```bash
# Frontend
ssh frontend-instance "docker logs vote"
ssh frontend-instance "docker logs result"

# Backend
ssh backend-instance "docker logs redis"
ssh backend-instance "docker logs worker"

# Database
ssh db-instance "docker logs postgres"
```

---

## Component Inventory Summary

### Infrastructure (7 components)
1. ✅ S3 Bucket (Terraform state)
2. ✅ DynamoDB Table (State locking)
3. ✅ VPC (Network isolation)
4. ✅ Internet Gateway (Public access)
5. ✅ NAT Gateway (Private egress)
6. ✅ Public Subnet (Frontend tier)
7. ✅ Private Subnet (Backend/DB tiers)

### Compute (3 instances)
1. ✅ Frontend Instance (t3.micro)
2. ✅ Backend Instance (t3.micro)
3. ✅ Database Instance (t3.micro)

### Application Services (5 containers)
1. ✅ Vote App (Python/Flask)
2. ✅ Redis (Message queue)
3. ✅ Worker (.NET processor)
4. ✅ PostgreSQL (Database)
5. ✅ Result App (Node.js)

### Monitoring (3 components - configured but not deployed)
1. ⚠️ Prometheus (Metrics collection)
2. ⚠️ Grafana (Visualization)
3. ⚠️ Node Exporter (System metrics)

### Security (3 security groups)
1. ✅ Frontend SG (Public access rules)
2. ✅ Backend SG (Private access rules)
3. ✅ Database SG (Private access rules)

**Total Deployed**: 18/21 components (86%)
**Status**: All critical components operational
**Missing**: Monitoring stack (optional for MVP)

---

## Next Steps

### For Presentation
1. ✅ All application components working
2. ✅ Data flow verified end-to-end
3. ⚠️ Monitoring dashboard (optional)
4. ✅ Architecture documented
5. ✅ Testing scripts ready

### For Production
1. 🔒 Secure database credentials (Ansible Vault)
2. 🔒 Restrict monitoring ports to admin IP
3. 📊 Deploy Prometheus + Grafana
4. 🔄 Implement high availability (multi-AZ)
5. 📈 Add Application Load Balancer
6. 🔐 Enable HTTPS with SSL certificates
7. 📊 CloudWatch integration
8. 🔄 Auto Scaling Groups
9. 💾 RDS instead of EC2 PostgreSQL
10. 📦 ElastiCache instead of EC2 Redis
