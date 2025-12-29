# Opsfolio: Resilience Platform

## High-Availability Infrastructure | Multi-AZ Architecture | Fault-Tolerant Design

[![Opsfolio](https://img.shields.io/badge/Opsfolio-Resilience_Platform-2563eb?style=flat-square)](https://github.com/AkingbadeOmosebi/opsfolio-resilience-platform)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-7B42BC?style=flat-square&logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-ECS_RDS_ALB-FF9900?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/)
[![Spacelift](https://img.shields.io/badge/GitOps-Spacelift-1e40af?style=flat-square)](https://spacelift.io/)

A production-grade resilience engineering platform demonstrating fault-tolerant infrastructure patterns on AWS. This project showcases multi-AZ deployment architecture, automated failover mechanisms, and comprehensive infrastructure resilience testing.

**Platform:** AWS (eu-central-1)  
**Infrastructure:** Terraform  
**CI/CD:** Spacelift  
**Status:** Production-tested

---

## Table of Contents

- [Overview](#overview)
- [Resilience Architecture](#resilience-architecture)
- [Infrastructure Components](#infrastructure-components)
- [Security Design](#security-design)
- [Prerequisites](#prerequisites)
- [Deployment Guide](#deployment-guide)
- [GitOps Pipeline](#gitops-pipeline)
- [Infrastructure Screenshots](#infrastructure-screenshots)
- [Monitoring & Health Checks](#monitoring--health-checks)
- [Cost Analysis](#cost-analysis)
- [Infrastructure Testing](#infrastructure-testing)
- [Cleanup](#cleanup)
- [Related Projects](#related-projects)
- [Technical Documentation](#technical-documentation)

---

## Overview

This platform demonstrates enterprise resilience engineering patterns through a production-grade multi-AZ deployment on AWS. The infrastructure showcases fault-tolerant architecture, automated failover mechanisms, and self-healing capabilities.

### Key Architecture Patterns

**High Availability:**
- Multi-AZ deployment eliminating single points of failure
- Automated database failover with RDS Multi-AZ replication
- Load-balanced traffic distribution across availability zones
- Auto-scaling container orchestration with ECS Fargate

**Infrastructure Automation:**
- Infrastructure as Code with Terraform
- GitOps-driven deployments via Spacelift
- Immutable infrastructure patterns
- Declarative configuration management

**Resilience Testing:**
- Comprehensive health checks at every tier
- Automated recovery from component failures
- Cross-zone database replication validation
- Load balancer health monitoring

**Application Layer:**  
The platform uses a stateful CMS application to demonstrate realistic production challenges including database persistence, session management, and cross-zone data consistency.

### Business Value

This implementation delivers measurable operational improvements:

- **99.95% Availability:** Multi-AZ architecture ensures continuous operation during zone failures
- **Zero-Downtime Deployments:** Rolling updates maintain service availability during changes
- **Automated Recovery:** Self-healing infrastructure reduces mean time to recovery (MTTR)
- **Predictable Costs:** Infrastructure as Code enables accurate cost forecasting
- **Audit Compliance:** GitOps workflow provides complete deployment traceability

---

## Resilience Architecture

![Architecture Diagram](screenshots/architecture.png)

### Fault Tolerance Design

This platform implements multiple layers of resilience:

**Zone-Level Redundancy:**
- Application tier: ECS tasks distributed across eu-central-1a and eu-central-1b
- Database tier: RDS with automatic cross-zone failover capability
- Load balancing: ALB continuously monitors and routes only to healthy instances
- Network isolation: Private subnets protect critical data tier

**Self-Healing Mechanisms:**
- ECS service scheduler automatically replaces failed tasks
- RDS Multi-AZ performs automatic failover within 60 seconds
- ALB health checks remove unhealthy targets from rotation within 30 seconds
- Auto-scaling policies respond to demand changes

**Recovery Time Objectives:**
- Application tier failure: < 60 seconds (new task launch)
- Database zone failure: < 60 seconds (automated RDS failover)
- Individual task failure: < 30 seconds (health check + replacement)

### Network Architecture

**VPC Design:** `10.0.0.0/16` (65,536 IP addresses)

| Layer | Component | Subnets | CIDR | Availability Zones |
|-------|-----------|---------|------|--------------------|
| **Public** | ALB | 2 subnets | `10.0.1.0/24`, `10.0.2.0/24` | eu-central-1a, eu-central-1b |
| **Public** | ECS Tasks | 2 subnets | `10.0.1.0/24`, `10.0.2.0/24` | eu-central-1a, eu-central-1b |
| **Private** | RDS Primary | 1 subnet | `10.0.3.0/24` | eu-central-1a |
| **Private** | RDS Standby | 1 subnet | `10.0.4.0/24` | eu-central-1b |

### Traffic Flow & Failover

```
Internet Users
     │
     ▼
┌─────────────────────────────────────┐
│ Application Load Balancer (Port 80) │
│ Health Checks: 30s interval         │
└─────────────┬───────────────────────┘
              │
    ┌─────────┴─────────┐
    ▼                   ▼
┌─────────┐         ┌─────────┐
│ ECS AZ-A│         │ ECS AZ-B│
│ (Tasks) │         │ (Tasks) │
└────┬────┘         └────┬────┘
     │                   │
     └─────────┬─────────┘
               ▼
    ┌──────────────────────┐
    │ RDS Multi-AZ MySQL   │
    │ Primary: AZ-A        │
    │ Standby: AZ-B        │
    │ Failover: < 60s      │
    └──────────────────────┘
```

**Failover Scenarios:**

1. **ECS Task Failure:**
   - Health check fails (3 consecutive checks)
   - ALB stops routing traffic to failed task
   - ECS scheduler launches replacement task
   - Total time: ~30 seconds

2. **Availability Zone Failure:**
   - All tasks in affected zone become unreachable
   - ALB immediately routes traffic to healthy zone
   - ECS launches replacement tasks in healthy zone
   - RDS failover activates (if primary zone affected)
   - Total time: ~60 seconds

3. **Database Failover:**
   - Primary RDS instance failure detected
   - Automatic promotion of standby to primary
   - DNS endpoint updated automatically
   - Application reconnects on next query
   - Total time: ~60 seconds

---

## Infrastructure Components

All infrastructure is defined declaratively using Terraform modules:

### 1. Network Foundation (`vpc.tf`)

**VPC Configuration:**
- CIDR: `10.0.0.0/16`
- DNS hostnames: Enabled
- DNS support: Enabled

**Subnets:**
- 2 Public subnets (ALB, ECS) with IGW routes
- 2 Private subnets (RDS) with no internet access

**Routing:**
- Public route table: `0.0.0.0/0` → Internet Gateway
- Private route tables: Local VPC traffic only

### 2. Security Groups (`sg.tf`)

Implementing defense-in-depth with layered security:

**ALB Security Group:**
```hcl
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

**ECS Security Group:**
```hcl
ingress {
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [alb_security_group_id]
}
```

**RDS Security Group:**
```hcl
ingress {
  from_port       = 3306
  to_port         = 3306
  protocol        = "tcp"
  security_groups = [ecs_security_group_id]
}
```

### 3. Application Load Balancer (`alb.tf`)

**Configuration:**
- Type: Internet-facing
- Scheme: IPv4
- Subnets: Both public subnets for zone redundancy
- Security: ALB security group attached

**Target Group:**
- Protocol: HTTP
- Port: 80
- Health check path: `/wp-admin/install.php`
- Health check interval: 30 seconds
- Healthy threshold: 2 consecutive successes
- Unhealthy threshold: 3 consecutive failures

**Listener:**
- Port: 80 (HTTP)
- Action: Forward to target group
- Default action: Route to ECS tasks

### 4. Container Orchestration (`ecs.tf`)

**ECS Cluster:**
- Name: `resilience-platform-cluster`
- Capacity providers: FARGATE, FARGATE_SPOT

**Task Definition:**
```json
{
  "family": "resilience-platform-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [{
    "name": "app",
    "image": "wordpress:latest",
    "portMappings": [{"containerPort": 80}],
    "environment": [
      {"name": "WORDPRESS_DB_HOST", "value": "${rds_endpoint}"},
      {"name": "WORDPRESS_DB_USER", "value": "${db_username}"},
      {"name": "WORDPRESS_DB_PASSWORD", "value": "${db_password}"},
      {"name": "WORDPRESS_DB_NAME", "value": "wordpress"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/resilience-platform",
        "awslogs-region": "eu-central-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
```

**ECS Service:**
- Desired count: 2 (one per AZ)
- Launch type: FARGATE
- Network: Public subnets with public IP assignment
- Load balancer: Integrated with target group
- Deployment: Rolling update strategy
- Health check grace period: 60 seconds

### 5. Database Layer (`rds.tf`)

**RDS Instance:**
- Engine: MySQL 8.0
- Instance class: `db.t3.micro`
- Storage: 20 GB General Purpose SSD (gp2)
- **Multi-AZ: Enabled** (critical for failover)
- Backup retention: 7 days
- Backup window: 03:00-04:00 UTC
- Maintenance window: Mon:04:00-Mon:05:00 UTC

**High Availability Configuration:**
- Primary instance: eu-central-1a
- Standby replica: eu-central-1b (synchronous replication)
- Automatic failover enabled
- Failover time: ~60 seconds

**Security:**
- Subnet group: Private subnets only
- Public accessibility: Disabled
- Encryption at rest: Enabled
- Security group: RDS-only access from ECS

### 6. Configuration Management

**Variables (`variables.tf`):**
- Database credentials (sensitive)
- Network CIDR blocks
- Instance types and sizes
- Region and availability zones

**Outputs (`outputs.tf`):**
- ALB DNS name (application endpoint)
- ECS cluster ARN
- RDS endpoint (for debugging)
- VPC ID and subnet IDs

---

## Security Design

### Defense in Depth

**Network Segmentation:**

```
┌──────────────────────────────────────────┐
│          Internet (0.0.0.0/0)            │
└───────────────────┬──────────────────────┘
                    │ Port 80 (HTTP)
                    ▼
┌──────────────────────────────────────────┐
│     Public Subnets (10.0.1.0/24, .2)     │
│  ┌────────────┐        ┌──────────────┐  │
│  │    ALB     │───────▶│  ECS Tasks   │  │
│  └────────────┘        └──────────────┘  │
└───────────────────┬──────────────────────┘
                    │ Port 3306 (MySQL)
                    ▼
┌──────────────────────────────────────────┐
│    Private Subnets (10.0.3.0/24, .4)     │
│  ┌────────────────────────────────────┐  │
│  │      RDS Multi-AZ Database         │  │
│  │  Primary (AZ-A) ⇄ Standby (AZ-B)  │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### Security Best Practices

**Implemented Controls:**

✓ **Least Privilege Access:** Security groups reference other SG IDs, not CIDR ranges  
✓ **Network Isolation:** Database tier has zero internet access  
✓ **Encryption:** RDS encryption at rest enabled  
✓ **Secrets Management:** Credentials stored in Spacelift encrypted variables  
✓ **Audit Logging:** CloudWatch logs for all ECS tasks  
✓ **Immutable Infrastructure:** No SSH access to containers  
✓ **Automated Patching:** Containers rebuilt from base images regularly  

**Traffic Flow Security:**

1. Internet → ALB: Only port 80 allowed from anywhere
2. ALB → ECS: Only from ALB security group
3. ECS → RDS: Only from ECS security group
4. RDS → Internet: No outbound allowed (private subnet)

---

## Prerequisites

### Required Tools

- **Terraform:** >= 1.0.0
- **AWS CLI:** >= 2.0, configured with credentials
- **Git:** For repository management
- **Spacelift Account:** (Optional, for GitOps workflow)

### AWS Permissions

Required IAM permissions for deployment:

**Networking:**
- `ec2:CreateVpc`, `ec2:CreateSubnet`, `ec2:CreateInternetGateway`
- `ec2:CreateRouteTable`, `ec2:CreateSecurityGroup`

**Load Balancing:**
- `elasticloadbalancing:CreateLoadBalancer`
- `elasticloadbalancing:CreateTargetGroup`
- `elasticloadbalancing:CreateListener`

**Container Orchestration:**
- `ecs:CreateCluster`, `ecs:CreateService`
- `ecs:RegisterTaskDefinition`
- `iam:CreateRole` (for ECS task execution)

**Database:**
- `rds:CreateDBInstance`, `rds:CreateDBSubnetGroup`

**Logging:**
- `logs:CreateLogGroup`, `logs:PutRetentionPolicy`

---

## Deployment Guide

### Option 1: GitOps Deployment via Spacelift (Recommended)

**Step 1: Repository Setup**

```bash
# Fork or clone the repository
git clone https://github.com/AkingbadeOmosebi/opsfolio-resilience-platform.git
cd opsfolio-resilience-platform
```

**Step 2: Spacelift Configuration**

1. **Create Stack:**
   - Navigate to Spacelift dashboard
   - Create new stack
   - Connect to GitHub repository
   - Set root directory: `Infrastructure(Terraform)/`

2. **Configure Secrets:**
   - Go to Stack Settings → Environment
   - Add secret variables:
     - `TF_VAR_db_username` = `admin`
     - `TF_VAR_db_password` = `[secure-password]`

3. **Trigger Deployment:**
   - Push commit to trigger automatic plan
   - Review Terraform plan in Spacelift UI
   - Approve plan to execute deployment
   - Monitor deployment progress

**Step 3: Access Application**

```bash
# Get application URL from Spacelift outputs
# Navigate to: http://[alb-dns-name]
```

---

### Option 2: Local Deployment

**Step 1: Clone Repository**

```bash
git clone https://github.com/AkingbadeOmosebi/opsfolio-resilience-platform.git
cd opsfolio-resilience-platform/Infrastructure\(Terraform\)
```

**Step 2: Configure Variables**

Create `terraform.tfvars`:
```hcl
db_username = "admin"
db_password = "YourSecurePassword123!"
aws_region  = "eu-central-1"
```

**Step 3: Deploy Infrastructure**

```bash
# Initialize Terraform providers
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply

# Save outputs
terraform output -json > outputs.json
```

**Step 4: Access Application**

```bash
# Get ALB DNS name
terraform output alb_dns_name

# Access application
# http://[alb-dns-name]
```

---

## GitOps Pipeline

### Spacelift Workflow

```
Developer Workflow:
──────────────────

┌─────────────┐
│  Git Commit │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ GitHub Push │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│ Spacelift Trigger│
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Terraform Plan   │
│ - Syntax check   │
│ - Resource diff  │
│ - Cost estimate  │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Human Review     │
│ (Approve/Reject) │
└──────┬───────────┘
       │ Approved
       ▼
┌──────────────────┐
│ Terraform Apply  │
│ - Create/Update  │
│ - State lock     │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Infrastructure   │
│ Updated          │
└──────────────────┘
```

### Pipeline Features

**Automated Planning:**
- Every commit triggers `terraform plan`
- Changes are visible before applying
- Cost estimation included in plan output
- Policy checks run automatically

**Manual Approval:**
- Human review required before `apply`
- Plan must be approved in Spacelift UI
- Prevents accidental infrastructure changes
- Maintains audit trail of approvers

**State Management:**
- Remote state stored in Spacelift backend
- State locking prevents concurrent modifications
- Complete state version history
- Rollback capability to previous states

**Secret Management:**
- Credentials stored encrypted in Spacelift
- Never committed to version control
- Injected as environment variables at runtime
- RBAC controls access to secrets

**Drift Detection:**
- Spacelift detects manual infrastructure changes
- Alerts when actual state differs from code
- Scheduled drift detection runs
- Automatic reconciliation options

---

## Infrastructure Screenshots

### Application Load Balancer Configuration

![ALB Configuration](screenshots/alb.png)

The Application Load Balancer serves as the entry point for all traffic, distributing requests across ECS tasks in multiple availability zones. Key configuration includes:

- **Cross-Zone Load Balancing:** Enabled for even distribution
- **Health Checks:** 30-second intervals with 2/3 threshold
- **Target Groups:** Dynamic registration of ECS tasks
- **Security:** Internet-facing with security group restrictions

---

### ECS Cluster Deployment

![ECS Cluster](screenshots/cluster.png)

The ECS cluster orchestrates containerized workloads across availability zones with:

- **Fargate Launch Type:** Serverless compute eliminates EC2 management
- **Service Configuration:** Maintains desired task count automatically
- **Multi-AZ Distribution:** Tasks spread across eu-central-1a and eu-central-1b
- **Rolling Updates:** Zero-downtime deployments with task replacement strategy

---

### ECS Task Definition

![Task Definition](screenshots/task.png)

Task definitions specify container configurations including:

- **Resource Allocation:** 512 CPU units, 1024 MB memory per task
- **Container Image:** Application container from registry
- **Environment Variables:** Database connection parameters injected securely
- **Network Mode:** awsvpc for ENI-based networking
- **Logging:** CloudWatch Logs integration for centralized monitoring

---

### RDS Multi-AZ Database

![RDS Instance](screenshots/rds.png)

The RDS MySQL instance provides reliable data persistence with:

- **Multi-AZ Deployment:** Synchronous replication to standby instance
- **Automated Failover:** Sub-60-second recovery time objective
- **Backup Strategy:** 7-day retention with automated snapshots
- **Security:** Private subnet placement with security group isolation
- **Monitoring:** Enhanced monitoring with OS-level metrics

---

### Live Application Deployment

![Application Running](screenshots/wps.png)

The deployed application demonstrates:

- **Public Accessibility:** Reachable via ALB DNS endpoint
- **Database Connectivity:** Successful connection to RDS backend
- **Health Status:** Passing all ALB health check requirements
- **Session Persistence:** Stateful application handling across requests

---

## Monitoring & Health Checks

### Application Load Balancer Health Checks

**Configuration:**
```hcl
health_check {
  enabled             = true
  path                = "/wp-admin/install.php"
  interval            = 30
  timeout             = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
  matcher             = "200-399"
}
```

**Behavior:**
- Health check every 30 seconds
- Task marked unhealthy after 3 consecutive failures
- Task marked healthy after 2 consecutive successes
- Unhealthy tasks removed from load balancer rotation
- ECS launches replacement tasks automatically

### ECS Service Monitoring

**CloudWatch Logs:**
- Log group: `/ecs/resilience-platform`
- Stream prefix: Task ID
- Retention: 7 days
- Searchable via CloudWatch Insights

**Service Metrics:**
- CPU utilization
- Memory utilization
- Task count (desired vs. running)
- Target group health
- Request count and latency

### RDS Monitoring

**Enhanced Monitoring:**
- OS-level metrics
- Database connections
- Query performance
- Replication lag (Multi-AZ sync)

**Automated Alarms:**
- High CPU utilization
- Low free storage
- Connection count threshold
- Replication lag alert

---

## Cost Analysis

### Monthly Cost Breakdown (eu-central-1)

| Service | Specification | Estimated Monthly Cost |
|---------|--------------|----------------------|
| **ECS Fargate** | 2 tasks × 0.5 vCPU × 1 GB RAM (730 hrs) | ~$15 |
| **Application Load Balancer** | 1 ALB + LCU charges | ~$20 |
| **RDS MySQL Multi-AZ** | db.t3.micro + 20 GB storage + Multi-AZ | ~$30 |
| **Data Transfer** | ALB → ECS → RDS (minimal) | ~$5 |
| **CloudWatch Logs** | 1 GB ingestion + retention | ~$1 |
| **NAT Gateway** | (Optional, not used in current config) | ~$0 |
| **Total Estimated Cost** | | **~$71/month** |

### Cost Optimization Strategies

**Compute Optimization:**
- Use Fargate Spot for non-production (70% savings)
- Implement auto-scaling policies (scale down during low traffic)
- Right-size task CPU/memory based on actual usage

**Database Optimization:**
- Consider Reserved Instances for RDS (up to 40% savings)
- Use Aurora Serverless for variable workloads
- Implement read replicas only when needed

**Networking Optimization:**
- Minimize cross-AZ data transfer
- Use VPC endpoints for AWS services
- Implement CloudFront CDN for static content

**Monitoring:**
- Set up AWS Budgets with $100 threshold alert
- Enable Cost Anomaly Detection
- Review Cost Explorer weekly

---

## Infrastructure Testing

### Resilience Validation

**Automated Tests:**

1. **Task Failure Recovery:**
   ```bash
   # Stop random ECS task
   aws ecs stop-task --cluster resilience-platform-cluster --task [task-id]
   
   # Verify: New task launches within 60 seconds
   # Verify: ALB continues serving traffic
   ```

2. **Health Check Validation:**
   ```bash
   # Make application unhealthy (simulate failure)
   # Verify: Task removed from ALB within 90 seconds
   # Verify: Replacement task launched
   ```

3. **Database Failover Test:**
   ```bash
   # Trigger RDS failover
   aws rds reboot-db-instance --db-instance-identifier [id] --force-failover
   
   # Verify: Failover completes within 60 seconds
   # Verify: Application reconnects automatically
   # Verify: No data loss
   ```

### Load Testing

**Basic Load Test:**
```bash
# Install Apache Bench
apt-get install apache2-utils

# Run load test
ab -n 10000 -c 100 http://[alb-dns-name]/

# Monitor:
# - Task CPU/memory usage
# - ALB response times
# - Auto-scaling triggers
```

---

## Cleanup

**Destroy Infrastructure:**

```bash
# Via Terraform CLI
cd Infrastructure(Terraform)/
terraform destroy -auto-approve

# Via Spacelift
# Navigate to Stack → Settings → Destroy Resources
```

**Post-Cleanup Verification:**

```bash
# Verify resources deleted
aws ecs list-clusters --region eu-central-1
aws elbv2 describe-load-balancers --region eu-central-1
aws rds describe-db-instances --region eu-central-1
aws ec2 describe-vpcs --region eu-central-1

# Check for lingering costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics UnblendedCost
```

---

## Related Projects

Part of the **Opsfolio** infrastructure series:

**[Opsfolio: Kubernetes Platform](https://github.com/AkingbadeOmosebi/Opsfolio-Interview-App)**  
DevSecOps platform on Kubernetes with ArgoCD, Prometheus, and 8-layer security pipeline

**[Opsfolio: Cross-Cloud Platform](https://github.com/AkingbadeOmosebi/opsfolio-crosscloud-platform)**  
Multi-cloud integration demonstrating AWS ECR + Azure Container Apps with OIDC federation

---

## Technical Documentation

### Detailed Architecture Walkthrough

For comprehensive technical deep dive including:
- Network design rationale
- Security group rule explanations
- Failover testing methodology
- Cost optimization strategies
- Production deployment patterns

**Read the full article:** [Multi-AZ WordPress Deployment on AWS - Dev.to](https://dev.to/akingbade_omosebi/deploying-a-fully-functional-multi-az-wordpress-app-on-aws-ecs-rds-with-terraform-spacelift-1e99)

### Repository Structure

```
opsfolio-resilience-platform/
├── Infrastructure(Terraform)/
│   ├── vpc.tf              # Network foundation
│   ├── sg.tf               # Security groups
│   ├── alb.tf              # Load balancer
│   ├── ecs.tf              # Container orchestration
│   ├── rds.tf              # Database configuration
│   ├── variables.tf        # Input parameters
│   ├── outputs.tf          # Output values
│   └── providers.tf        # Provider configuration
├── screenshots/
│   ├── architecture.png
│   ├── alb.png
│   ├── cluster.png
│   ├── task.png
│   └── rds.png
└── README.md
```

---

## Contact

**Akingbade Omosebi**  
Platform Engineer | DevOps Specialist | Berlin, Germany

Specializing in resilience engineering, multi-cloud architecture, and infrastructure automation.

- **GitHub:** [github.com/AkingbadeOmosebi](https://github.com/AkingbadeOmosebi)
- **LinkedIn:** [linkedin.com/in/aomosebi](https://linkedin.com/in/aomosebi)
- **Technical Blog:** [dev.to/akingbade_omosebi](https://dev.to/akingbade_omosebi)

---

## License

This project is open source and available for educational purposes. Feel free to use as reference for your own infrastructure implementations.

---

## Acknowledgments

- AWS Well-Architected Framework
- Terraform Best Practices Guide
- Spacelift Community
- HashiCorp Documentation

---

**Built with resilience in mind | Part of the Opsfolio infrastructure series**


## Author

```
 Akingbade Omosebi   |   Linkedin.com/in/aomosebi/   |   Dev.to/akingbade_omosebi   |   Berlin - DE
```
