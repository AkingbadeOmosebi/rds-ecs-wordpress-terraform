# ECS WordPress with Terraform & Spacelift

This project deploys a containerized WordPress site on AWS ECS Fargate with an RDS backend and an Application Load Balancer, managed with Terraform and Spacelift.
# 🚀 Deploy a Multi-AZ WordPress App on AWS with ECS, RDS, Terraform & Spacelift

Hey! 👋 I’m Akingbade Omosebi — this repo shows how I deployed a **real, production-style** WordPress app on AWS.  
This setup uses:
- **ECS Fargate** for containers
- **ALB (Application Load Balancer)** for traffic routing
- **RDS MySQL** in Private Subnets for storage
- **Terraform** for Infrastructure as Code
- **Spacelift** for CI/CD automation

Everything is **split by files**, version-controlled, and tested live on AWS `eu-central-1` (Frankfurt).

---

## 📌 **What’s in here**

- `vpc.tf` → Defines the VPC, Subnets, Internet Gateway
- `security.tf` → Security Groups for ALB, ECS, and RDS
- `alb.tf` → Load Balancer, Listener, Target Group
- `ecs.tf` → ECS Cluster, Service, Task Definition for WordPress
- `rds.tf` → MySQL DB with Multi-AZ failover
- `variables.tf` → Inputs (with `sensitive` marked where needed)
- `outputs.tf` → Outputs like ALB DNS name, Cluster name, RDS endpoint

---

## ✅ **How it works**

**1️⃣ Public Subnets** → Hold ALB and ECS Tasks, with Internet access via IGW  
**2️⃣ Private Subnets** → Hold RDS, isolated from public traffic  
**3️⃣ ALB** → Receives HTTP requests and routes them to ECS Tasks  
**4️⃣ ECS Tasks** → Run official WordPress containers, talk to RDS  
**5️⃣ RDS** → Stores WordPress content securely in Multi-AZ mode  
**6️⃣ Spacelift** → Runs `terraform plan` & `apply` on every commit

---

## 🛡️ **Security Design**

- ALB SG → allows HTTP from anywhere
- ECS SG → only accepts traffic from ALB SG
- RDS SG → only accepts traffic from ECS SG on port 3306
- No public access to RDS — Private Subnet only

---

## 📌 **How to Use**

**1️⃣ Clone**
```bash
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>


2️⃣ Setup your terraform.tfvars or environment vars for secrets
db_username = "admin"
db_password = "YOUR_STRONG_PASSWORD"

3️⃣ Initialize & Plan
terraform init
terraform plan

4️⃣ Apply
terraform apply


🚦 CI/CD with Spacelift
Every push triggers a plan

Changes reviewed → approved → apply

Secrets handled via Spacelift Environment Variables

No credentials in .tf files or Git history


✅ Tips
Always run a terraform destroy when you’re done.

Keep your AWS account clean.

Add a budget alarm!


Here are some screenshots

## 📸 Screenshots

![Architecture](https://github.com/AkingbadeOmosebi/rds-ecs-wordpress-terraform/blob/main/screenshots/architecture.png?raw=true)


🫡 Author
Akingbade Omosebi
Dev.to | LinkedIn | GitHub