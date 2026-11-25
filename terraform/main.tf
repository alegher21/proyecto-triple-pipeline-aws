terraform {
  required_version = ">= 1.5.0"

  # Estado remoto en S3 (bucket/key se pasan en "terraform init -backend-config")
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  # Excluye la zona use1-az3 (sin soporte histórico de Fargate en us-east-1)
  filter {
    name   = "availability-zone-id"
    values = ["use1-az1", "use1-az2", "use1-az4", "use1-az5", "use1-az6"]
  }
}

# Rol IAM existente (AWS Academy Learner Lab no permite crear roles IAM)
data "aws_iam_role" "lab_role" {
  name = var.lab_role_name
}

# Repositorios Amazon ECR
resource "aws_ecr_repository" "frontend" {
  name         = "${var.project_name}-frontend"
  force_delete = true
}

resource "aws_ecr_repository" "backend" {
  name         = "${var.project_name}-backend"
  force_delete = true
}

# Security Group (Puertos 80 Frontend y 3000 Backend)
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-sg"
  description = "Permitir trafico HTTP 80 y API 3000"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-frontend"
  retention_in_days = 1
}

# Clúster ECS
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

# Task Definitions Base
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name         = "backend"
    image        = "${aws_ecr_repository.backend.repository_url}:latest"
    essential    = true
    portMappings = [{ containerPort = 3000, hostPort = 3000 }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.backend.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "backend"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name         = "frontend"
    image        = "${aws_ecr_repository.frontend.repository_url}:latest"
    essential    = true
    portMappings = [{ containerPort = 80, hostPort = 80 }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.frontend.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "frontend"
      }
    }
  }])
}

# Servicios ECS (desired_count = 0 hasta que Pipeline 3 despliegue)
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}
