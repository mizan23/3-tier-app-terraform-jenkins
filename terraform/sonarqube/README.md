# SonarQube on AWS with Terraform

This Terraform stack creates a dedicated SonarQube server on AWS EC2.

## What it creates

- 1 EC2 instance (default `t3.large`)
- 1 security group (ports `22` and `9000`)
- Docker + Docker Compose installation via user data
- SonarQube Community + PostgreSQL containers

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your VPC/subnet/key/profile

terraform init
terraform plan
terraform apply
```

After apply, open the output `sonarqube_url` in browser.

## Notes

- First startup can take a few minutes.
- Default SonarQube login: `admin` / `admin` (you will be prompted to change it).
- For production, restrict `allowed_cidrs` and use a domain + HTTPS behind ALB.
