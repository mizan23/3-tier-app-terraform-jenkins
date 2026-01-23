# BMI Health Tracker - Terraform Infrastructure

This directory contains Infrastructure as Code (IaC) for deploying the BMI Health Tracker 3-tier application on AWS using Terraform.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Terraform Modules](#terraform-modules)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment Process](#deployment-process)
- [State Management](#state-management)
- [Outputs](#outputs)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

---

## 📖 Overview

This Terraform configuration automates the deployment of a production-ready 3-tier web application with:

- **Frontend**: React app served by Nginx on EC2
- **Backend**: Node.js + Express API with PM2 on EC2
- **Database**: PostgreSQL on EC2
- **Load Balancer**: Application Load Balancer with SSL/TLS
- **DNS**: Route53 A record pointing to ALB
- **SSL Certificate**: Automated Let's Encrypt certificate via Certbot

### Key Features

✅ **Modular Design** - Reusable, composable modules  
✅ **Automated Deployment** - User data scripts handle all setup  
✅ **SSL/TLS Support** - Automatic certificate generation and renewal  
✅ **High Availability** - ALB across multiple availability zones  
✅ **Infrastructure as Code** - Version-controlled, reproducible infrastructure  
✅ **State Management** - Remote state storage in S3  

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     Route53 (DNS Module)                    │ │
│  │  A Record: domain.com → ALB                                 │ │
│  └───────────────────────┬────────────────────────────────────┘ │
│                          │                                        │
│  ┌───────────────────────▼────────────────────────────────────┐ │
│  │         Application Load Balancer (ALB Module)             │ │
│  │  - HTTPS:443 → Frontend Target Group                       │ │
│  │  - HTTP:80 → Redirect to HTTPS                             │ │
│  │  - Public Subnets (Multi-AZ)                                │ │
│  └───────────────────────┬────────────────────────────────────┘ │
│                          │                                        │
│  ┌───────────────────────▼────────────────────────────────────┐ │
│  │              EC2 Module - Application Tier                  │ │
│  │                                                              │ │
│  │  ┌────────────────────────────────────────────────────┐    │ │
│  │  │  Frontend EC2 (Private Subnet)                     │    │ │
│  │  │  - Nginx web server (port 80)                      │    │ │
│  │  │  - React static files                              │    │ │
│  │  │  - Certbot + Let's Encrypt SSL                     │    │ │
│  │  │  - IAM Role: Route53 DNS challenge                 │    │ │
│  │  └────────────────┬───────────────────────────────────┘    │ │
│  │                   │ Proxy /api/* requests                   │ │
│  │  ┌────────────────▼───────────────────────────────────┐    │ │
│  │  │  Backend EC2 (Private Subnet)                      │    │ │
│  │  │  - Node.js + Express API (port 3000)               │    │ │
│  │  │  - PM2 process manager                             │    │ │
│  │  │  - Health checks, auto-restart                     │    │ │
│  │  └────────────────┬───────────────────────────────────┘    │ │
│  │                   │ PostgreSQL connection                   │ │
│  │  ┌────────────────▼───────────────────────────────────┐    │ │
│  │  │  Database EC2 (Private Subnet)                     │    │ │
│  │  │  - PostgreSQL 14/15/16 (port 5432)                 │    │ │
│  │  │  - Automated schema migrations                     │    │ │
│  │  │  - Configured for remote connections               │    │ │
│  │  └────────────────────────────────────────────────────┘    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    IAM Module                                │ │
│  │  - Frontend IAM Role for Certbot                            │ │
│  │  - Route53 permissions for DNS-01 challenge                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
terraform/
├── backend.tf                      # Terraform backend configuration (S3)
├── backend-config.tfbackend        # Backend config values (gitignored)
├── backend-config.tfbackend.example # Template for backend config
├── main.tf                         # Root module - orchestrates everything
├── variables.tf                    # Input variables declaration
├── outputs.tf                      # Output values after deployment
├── terraform.tfvars                # Variable values (gitignored)
├── terraform.tfvars.example        # Template for variables
├── deploy.sh                       # Deployment automation script
├── README.md                       # This file
│
└── modules/                        # Reusable Terraform modules
    │
    ├── iam/                        # IAM roles and policies
    │   ├── main.tf                 # IAM role for Certbot
    │   ├── variables.tf            # Module inputs
    │   └── outputs.tf              # Instance profile names
    │
    ├── ec2/                        # EC2 instances for 3 tiers
    │   ├── main.tf                 # EC2 instance resources
    │   ├── variables.tf            # Module inputs
    │   ├── outputs.tf              # Instance IDs, private IPs
    │   ├── certificate-wait.tf     # Waits for SSL cert generation
    │   └── templates/              # User data scripts
    │       ├── database-init.sh    # PostgreSQL setup
    │       ├── backend-init.sh     # Node.js + PM2 setup
    │       └── frontend-init.sh    # Nginx + React + Certbot
    │
    ├── alb/                        # Application Load Balancer
    │   ├── main.tf                 # ALB, target group, listeners
    │   ├── variables.tf            # Module inputs
    │   └── outputs.tf              # ALB DNS name, ARN
    │
    └── dns/                        # Route53 DNS configuration
        ├── main.tf                 # A record alias to ALB
        ├── variables.tf            # Module inputs
        └── outputs.tf              # DNS record info
```

---

## 🧩 Terraform Modules

### 1. **IAM Module** (`modules/iam/`)

**Purpose**: Creates IAM roles and policies for EC2 instances.

**Resources**:
- `aws_iam_role.frontend_certbot` - Allows frontend EC2 to assume role
- `aws_iam_role_policy.route53_certbot` - Grants Route53 permissions
- `aws_iam_instance_profile.frontend` - Attaches role to EC2

**Why Needed**: 
- Certbot uses DNS-01 challenge for SSL certificates
- Requires Route53 permissions to create/delete TXT records
- Follows least-privilege security principle

**Key Permissions**:
```json
{
  "route53:ListHostedZones",
  "route53:GetChange",
  "route53:ChangeResourceRecordSets",
  "route53:ListResourceRecordSets"
}
```

### 2. **EC2 Module** (`modules/ec2/`)

**Purpose**: Provisions and configures all three EC2 instances.

**Resources**:
- `aws_instance.database` - PostgreSQL database server
- `aws_instance.backend` - Node.js API server
- `aws_instance.frontend` - Nginx web server

**Key Features**:
- **User Data Scripts**: Automated setup via bash scripts
- **Template Variables**: Dynamic configuration injection
- **Dependency Management**: Backend waits for database, frontend waits for backend
- **Certificate Waiting**: Special resource waits for SSL cert before completing

**User Data Scripts**:

| Script | Purpose | Key Actions |
|--------|---------|-------------|
| `database-init.sh` | Sets up PostgreSQL | Install PostgreSQL, create database/user, configure remote access, run migrations |
| `backend-init.sh` | Sets up Node.js API | Install Node.js, clone repo, configure .env, start with PM2 |
| `frontend-init.sh` | Sets up Nginx + React | Install Nginx, build React app, configure Nginx proxy, run Certbot |

**Terraform Interpolation**:
```hcl
user_data = templatefile("${path.module}/templates/backend-init.sh", {
  db_host      = aws_instance.database.private_ip
  db_port      = var.db_port
  backend_port = var.backend_port
  # ... more variables
})
```

### 3. **ALB Module** (`modules/alb/`)

**Purpose**: Creates internet-facing load balancer with SSL termination.

**Resources**:
- `aws_lb.main` - Application Load Balancer
- `aws_lb_target_group.frontend` - Target group for frontend EC2
- `aws_lb_target_group_attachment.frontend` - Registers frontend instance
- `aws_lb_listener.https` - HTTPS:443 listener
- `aws_lb_listener.http` - HTTP:80 listener (redirects to HTTPS)

**Health Checks**:
- **Path**: `/` (Nginx serves React app)
- **Interval**: 30 seconds
- **Healthy threshold**: 2 consecutive successes
- **Unhealthy threshold**: 3 consecutive failures

**Listener Rules**:
1. **HTTPS (443)**: Forward to frontend target group
2. **HTTP (80)**: Redirect to HTTPS with 301 status

### 4. **DNS Module** (`modules/dns/`)

**Purpose**: Creates Route53 DNS record pointing to ALB.

**Resources**:
- `aws_route53_record.main` - A record (Alias type)

**Configuration**:
```hcl
alias {
  name                   = "dualstack.${alb_dns_name}"
  zone_id                = alb_zone_id
  evaluate_target_health = true
}
```

**Benefits**:
- No extra cost for alias records
- Automatic IPv4/IPv6 support (dualstack)
- Health-based routing if ALB is unhealthy

---

## ✅ Prerequisites

### AWS Resources (Create These First)

1. **VPC with Subnets**
   - 1 VPC
   - 2 Public subnets (for ALB, different AZs)
   - 2 Private subnets (for EC2, different AZs)
   - NAT Gateway in public subnet
   - Internet Gateway attached to VPC

2. **Security Groups**

   | Security Group | Inbound Rules | Purpose |
   |----------------|---------------|---------|
   | ALB SG | HTTP (80) from 0.0.0.0/0<br>HTTPS (443) from 0.0.0.0/0 | Internet access |
   | Frontend SG | HTTP (80) from ALB SG<br>SSH (22) from bastion/your IP | ALB to frontend |
   | Backend SG | TCP (3000) from Frontend SG<br>SSH (22) from bastion/your IP | Frontend to backend |
   | Database SG | PostgreSQL (5432) from Backend SG<br>SSH (22) from bastion/your IP | Backend to database |

3. **Route53 Hosted Zone**
   - Domain registered and hosted zone created
   - Note the hosted zone ID

4. **EC2 Key Pair**
   - Create or import SSH key pair
   - Save private key securely

5. **S3 Bucket for Terraform State**
   - Create S3 bucket (e.g., `your-org-tf-states`)
   - Enable versioning (recommended)
   - Optional: Enable encryption

### Local Tools

- Terraform >= 1.0
- AWS CLI configured with credentials
- Git (for cloning repository)

---

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/sarowar-alam/3-tier-app-terraform-jenkins.git
cd 3-tier-app-terraform-jenkins/terraform
```

### 2. Configure Backend

```bash
# Copy template
cp backend-config.tfbackend.example backend-config.tfbackend

# Edit with your values
nano backend-config.tfbackend
```

Update:
```hcl
bucket  = "your-terraform-state-bucket"
profile = "your-aws-profile"
```

### 3. Configure Variables

```bash
# Copy template
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Update all placeholders (search for `your-` and `xxx`).

### 4. Initialize Terraform

```bash
terraform init -backend-config=backend-config.tfbackend
```

This will:
- Download AWS provider plugins
- Initialize S3 backend
- Create `.terraform/` directory

### 5. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the execution plan carefully. Should create:
- 3 EC2 instances
- 1 ALB with target group
- IAM role and instance profile
- Route53 A record

### 6. Apply Configuration

```bash
terraform apply tfplan
```

Deployment takes ~10-15 minutes due to:
- EC2 instance launches
- Software installation (PostgreSQL, Node.js, Nginx)
- SSL certificate generation (Let's Encrypt)

### 7. Verify Deployment

```bash
# Get outputs
terraform output

# Test application
curl https://your-domain.com
```

---

## ⚙️ Configuration

### Input Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `aws_region` | string | AWS region | `ap-south-1` |
| `aws_profile` | string | AWS CLI profile | `default` |
| `vpc_id` | string | VPC ID | `vpc-xxx` |
| `public_subnet_ids` | list(string) | Public subnet IDs | `["subnet-xxx", "subnet-yyy"]` |
| `private_subnet_ids` | list(string) | Private subnet IDs | `["subnet-zzz", "subnet-aaa"]` |
| `alb_security_group_id` | string | ALB security group ID | `sg-xxx` |
| `frontend_security_group_id` | string | Frontend SG ID | `sg-yyy` |
| `backend_security_group_id` | string | Backend SG ID | `sg-zzz` |
| `database_security_group_id` | string | Database SG ID | `sg-aaa` |
| `hosted_zone_id` | string | Route53 hosted zone ID | `Z1234567890ABC` |
| `domain_name` | string | Application domain | `bmi.example.com` |
| `key_name` | string | EC2 key pair name | `my-key` |
| `instance_type_frontend` | string | Frontend instance type | `t3.small` |
| `instance_type_backend` | string | Backend instance type | `t3.small` |
| `instance_type_database` | string | Database instance type | `t3.medium` |
| `git_repo_url` | string | GitHub repository URL | `https://github.com/...` |
| `git_branch` | string | Git branch | `main` |
| `db_name` | string | PostgreSQL database name | `bmi_db` |
| `db_user` | string | Database username | `bmi_user` |
| `db_password` | string | Database password | (strong password) |

### Default Values

Some variables have defaults in `variables.tf`:
- `project_name` = `"bmi-health-tracker"`
- `environment` = `"production"`
- `backend_port` = `3000`
- `db_port` = `5432`

---

## 🔄 Deployment Process

### Terraform Execution Flow

1. **Initialization** (`terraform init`)
   - Downloads providers
   - Configures S3 backend

2. **Planning** (`terraform plan`)
   - Reads configuration files
   - Compares with current state
   - Shows what will change

3. **Application** (`terraform apply`)
   - Creates resources in dependency order
   - Handles failures and retries

### Resource Creation Order

```
1. IAM Role & Instance Profile
   ↓
2. Database EC2 Instance
   ↓ (wait for database ready)
3. Backend EC2 Instance
   ↓ (wait for backend ready)
4. Frontend EC2 Instance
   ↓ (wait for SSL certificate)
5. Application Load Balancer
   ↓
6. Target Group Attachment
   ↓
7. Route53 A Record
```

### User Data Execution

Each EC2 instance runs its user data script on first boot:

**Database** (`database-init.sh`):
1. Update system packages
2. Install PostgreSQL
3. Create database and user
4. Configure for remote access
5. Run SQL migrations

**Backend** (`backend-init.sh`):
1. Update system packages
2. Install Node.js 20.x LTS
3. Install PM2 globally
4. Clone repository
5. Create `.env` file
6. Install npm dependencies
7. Start application with PM2

**Frontend** (`frontend-init.sh`):
1. Update system packages
2. Install Nginx, Node.js, Certbot
3. Clone repository
4. Build React production bundle
5. Deploy to Nginx web root
6. Configure Nginx reverse proxy
7. Run Certbot for SSL certificate
8. Configure Nginx for HTTPS

### Certificate Generation

The frontend instance:
1. Waits for DNS to propagate (60 seconds)
2. Runs Certbot with DNS-01 challenge
3. Uses IAM role to create Route53 TXT records
4. Receives SSL certificate from Let's Encrypt
5. Configures Nginx with SSL
6. Sets up auto-renewal cron job

Terraform waits for certificate before marking deployment complete.

---

## 💾 State Management

### Remote State (S3 Backend)

Terraform state is stored in S3 for:
- **Team Collaboration** - Multiple users can access
- **State Locking** - Prevents concurrent modifications
- **Versioning** - History of all state changes
- **Security** - Encrypted at rest

### Backend Configuration

File: `backend.tf`
```hcl
backend "s3" {
  key     = "bmi-health-tracker/terraform.tfstate"
  region  = "ap-south-1"
  encrypt = true
}
```

Values provided via `backend-config.tfbackend`:
```hcl
bucket  = "your-terraform-state-bucket"
profile = "your-aws-profile"
```

### State Commands

```bash
# Show current state
terraform state list

# Show specific resource
terraform state show aws_instance.database

# Remove resource from state (doesn't delete)
terraform state rm aws_instance.database

# Import existing resource
terraform import aws_instance.database i-1234567890abcdef0

# Pull remote state
terraform state pull > terraform.tfstate.backup
```

---

## 📤 Outputs

After successful deployment, Terraform outputs:

### Application Access
- `application_url` - Main HTTPS URL
- `alb_dns_name` - ALB DNS for testing

### EC2 Instance Details
- `database_instance_id` - Database instance ID
- `database_private_ip` - Database private IP
- `backend_instance_id` - Backend instance ID
- `backend_private_ip` - Backend private IP
- `frontend_instance_id` - Frontend instance ID
- `frontend_private_ip` - Frontend private IP

### Infrastructure Details
- `alb_arn` - Load balancer ARN
- `target_group_arn` - Frontend target group ARN
- `route53_record_name` - DNS record name
- `iam_role_arn` - Frontend IAM role ARN

### SSH Access
- `ssh_command_database` - SSH command for database
- `ssh_command_backend` - SSH command for backend
- `ssh_command_frontend` - SSH command for frontend

Example output:
```bash
$ terraform output

application_url = "https://bmi.example.com"
alb_dns_name = "bmi-alb-1234567890.ap-south-1.elb.amazonaws.com"
database_private_ip = "10.0.1.10"
backend_private_ip = "10.0.1.15"
frontend_private_ip = "10.0.1.20"
```

---

## 🔧 Advanced Topics

### Customizing Instance Types

Edit `terraform.tfvars`:
```hcl
instance_type_frontend = "t3.medium"  # Upgrade for more traffic
instance_type_backend  = "t3.medium"
instance_type_database = "t3.large"   # More resources for DB
```

### Using Specific AMI

```hcl
ami_id = "ami-0abc123def456"  # Custom Ubuntu image
```

### Adding Tags

```hcl
common_tags = {
  CostCenter = "Engineering"
  Owner      = "Platform Team"
}
```

### Modifying Database Configuration

Edit `modules/ec2/templates/database-init.sh`:
```bash
# Increase max connections
sed -i "s/max_connections = 100/max_connections = 500/" $PG_CONF

# Increase shared buffers
sed -i "s/shared_buffers = 128MB/shared_buffers = 512MB/" $PG_CONF
```

### Adding DynamoDB State Locking

1. Create DynamoDB table:
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

2. Update `backend-config.tfbackend`:
```hcl
dynamodb_table = "terraform-state-lock"
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Terraform Init Fails

**Error**: `Error configuring S3 Backend: NoSuchBucket`

**Solution**:
- Verify S3 bucket exists
- Check bucket name in `backend-config.tfbackend`
- Ensure AWS credentials have S3 access

#### 2. Apply Fails on EC2 Instance

**Error**: `Error launching source instance: InvalidKeyPair.NotFound`

**Solution**:
- Verify key pair exists in AWS region
- Check `key_name` in `terraform.tfvars`

#### 3. SSL Certificate Not Generated

**Check**:
```bash
# SSH to frontend instance
ssh -i your-key.pem ubuntu@frontend-ip

# Check Certbot logs
sudo cat /var/log/letsencrypt/letsencrypt.log

# Check user data logs
sudo cat /var/log/user-data.log
```

**Common Causes**:
- IAM role missing Route53 permissions
- Hosted zone ID incorrect
- Domain not propagated yet
- Rate limit from Let's Encrypt

#### 4. Backend Can't Connect to Database

**Check**:
```bash
# SSH to backend instance
ssh -i your-key.pem ubuntu@backend-ip

# Check PM2 logs
pm2 logs bmi-backend

# Test database connection
nc -zv <database-ip> 5432
```

**Solution**:
- Verify security group allows backend SG → database SG on port 5432
- Check database is running: `sudo systemctl status postgresql`

#### 5. Target Group Unhealthy

**Check**:
- AWS Console → EC2 → Target Groups → Health checks
- Frontend Nginx status: `sudo systemctl status nginx`
- Frontend logs: `sudo tail -f /var/log/nginx/error.log`

**Solution**:
- Verify security group allows ALB SG → frontend SG on port 80
- Check Nginx is serving on port 80

### Debugging Commands

```bash
# Validate Terraform syntax
terraform validate

# Format Terraform files
terraform fmt -recursive

# Show detailed logs
TF_LOG=DEBUG terraform apply

# Check state
terraform show

# Refresh state from AWS
terraform refresh

# Destroy specific resource
terraform destroy -target=aws_instance.frontend
```

---

## 📚 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Module Documentation](https://developer.hashicorp.com/terraform/language/modules)
- [AWS EC2 User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [Certbot DNS Plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins)

---

## 🧹 Cleanup

To destroy all resources:

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm with 'yes'
```

**Warning**: This will permanently delete:
- All EC2 instances
- ALB and target groups
- Route53 records (your domain will stop resolving)

The following are NOT deleted (manual cleanup required):
- VPC and subnets
- Security groups
- Route53 hosted zone
- S3 Terraform state bucket
- EC2 key pair

---

## 🤝 Contributing

For students and contributors:

1. Test changes in a separate environment
2. Update documentation for any changes
3. Follow Terraform best practices
4. Add comments for complex logic
5. Test destroy and re-apply

---

## 📝 Notes

- **Cost**: Running this infrastructure costs ~$30-50/month
- **Security**: Use strong database passwords
- **Backup**: Set up automated database backups
- **Monitoring**: Consider adding CloudWatch alarms
- **Scaling**: For production, use Auto Scaling Groups

---

**🎉 Happy Terraforming!**

For manual deployment instructions, see `../manual-implementation/README.md`

---

## 🧑‍💻 Author

**Md. Sarowar Alam**  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: [linkedin.com/in/sarowar](https://www.linkedin.com/in/sarowar/)

---

---
