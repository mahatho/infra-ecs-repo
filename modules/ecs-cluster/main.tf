provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC (simple single AZ or multi-AZ depending on variable)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
  name = var.name
  cidr = var.vpc_cidr
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets  = var.public_subnets
  enable_nat_gateway = false
}

resource "aws_security_group" "ecs_sg" {
  name = "${var.name}-ecs-sg"
  vpc_id = module.vpc.vpc_id
  description = "Allow HTTP and ephemeral for Fargate"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"
  setting {
    name = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }
}

# IAM role for task execution
resource "aws_iam_role" "task_exec" {
  name = "${var.name}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "task_execution_attach" {
  role = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



# outputs
output "cluster_name" {
  value = aws_ecs_cluster.this.name
}
output "vpc_id" {
  value = module.vpc.vpc_id
}
output "public_subnets" {
  value = module.vpc.public_subnets
}
output "security_group_id" {
  value = aws_security_group.ecs_sg.id
}
output "task_execution_role_arn" {
  value = aws_iam_role.task_exec.arn
}
