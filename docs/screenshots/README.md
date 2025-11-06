# Project Screenshots

This directory contains visual documentation of the project's key components and functionality.

## Screenshots Included

### 1. Infrastructure Diagram
**File**: `infrastructure-diagram.drawio`
- ✅ Complete AWS architecture (draw.io format)
- VPC, subnets, security groups
- EC2 instances and their roles
- Data flow visualization

**How to edit**: Open `infrastructure-diagram.drawio` with [draw.io](https://app.diagrams.net/)

### 2. Grafana Dashboard ✅
**File**: `grafana-dashboard.png` (188KB, 1673×853)
- ✅ Live monitoring dashboard
- Prometheus metrics visualization
- CPU, Memory, Network across 3 instances
- Real-time infrastructure health monitoring

**Shows**: Professional monitoring setup with Grafana + Prometheus

### 3. Stress Test + Result Demo ✅
**File**: `stress-test-result-demo.png` (117KB, 1853×1041)
- ✅ Combined view: Load testing + live results
- Vote submission rate: 40+ votes/second
- Parallel connection handling
- Real-time vote processing and display

**Shows**: End-to-end functionality under load

### 4. Terraform Destroy Automation ✅
**File**: `terraform-destroy-automation.png` (313KB, 1209×1345)
- ✅ Complete infrastructure teardown
- 29 AWS resources destroyed
- Infrastructure as Code lifecycle
- Reproducible and disposable infrastructure

**Shows**: True automation - deploy AND destroy with single commands

---

## Usage in Documentation

These screenshots are referenced in:
- `README.md` - Main project overview
- `docs/COMPONENTS_GUIDE.md` - Architecture explanation
- `presentation/PRESENTATION.md` - Visual aids

## Adding New Screenshots

1. Place PNG files in this directory
2. Use descriptive names (lowercase, hyphens)
3. Update this README
4. Reference in relevant documentation
5. Commit with message: "Add [description] screenshot"

---

**Note**: All screenshots should sanitize sensitive information (IPs replaced with placeholders where needed for security).
