terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = var.subnet_id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "sonarqube" {
  name        = "${var.project_name}-sg"
  description = "Security group for SonarQube server"
  vpc_id      = var.vpc_id

  ingress {
    description = "SonarQube UI"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_instance" "sonarqube" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.sonarqube.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg
    sysctl -w vm.max_map_count=524288
    echo "vm.max_map_count=524288" > /etc/sysctl.d/99-sonarqube.conf
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
    systemctl start docker

    mkdir -p /opt/sonarqube
    cat > /opt/sonarqube/docker-compose.yml <<'COMPOSE'
    services:
      db:
        image: postgres:15
        container_name: sonarqube-db
        environment:
          POSTGRES_USER: sonar
          POSTGRES_PASSWORD: sonarpass
          POSTGRES_DB: sonarqube
        volumes:
          - sonarqube_db:/var/lib/postgresql/data
        restart: always

      sonarqube:
        image: sonarqube:community
        container_name: sonarqube
        depends_on:
          - db
        ports:
          - "9000:9000"
        environment:
          SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonarqube
          SONAR_JDBC_USERNAME: sonar
          SONAR_JDBC_PASSWORD: sonarpass
        volumes:
          - sonarqube_data:/opt/sonarqube/data
          - sonarqube_logs:/opt/sonarqube/logs
          - sonarqube_extensions:/opt/sonarqube/extensions
        restart: always

    volumes:
      sonarqube_db:
      sonarqube_data:
      sonarqube_logs:
      sonarqube_extensions:
    COMPOSE

    docker compose -f /opt/sonarqube/docker-compose.yml up -d
  EOF

  tags = {
    Name        = var.project_name
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_route_table_association.public]
}
