# ALB용 SG
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security Group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.name}-alb-sg"
    Project   = var.name
    ManagedBy = "Terraform"
  }
}

# EKS용 SG
resource "aws_security_group" "eks" {
  name        = "${var.name}-eks-sg"
  description = "Security Group for EKS Node/Service"
  vpc_id      = var.vpc_id

  # ALB → EKS
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 30000
    to_port         = 30000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Node 간 내부 통신 허용
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }

  # ✅ EKS Control Plane → Node (서울 리전 CIDR 허용)
  ingress {
    description = "Allow EKS Control Plane (Kubelet TLS)"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["13.124.0.0/16", "3.35.0.0/16"]
  }

  ingress {
    description = "Allow EKS Control Plane (API Server)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["13.124.0.0/16", "3.35.0.0/16","210.92.246.130/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.name}-eks-sg"
    Project   = var.name
    ManagedBy = "Terraform"
  }
}
