# ALB용 Security Group
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  # HTTP, HTTPS 모두 오픈
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

  tags = { Name = "${var.name}-alb-sg" }
}

# EKS Node/Service용 Security Group
resource "aws_security_group" "eks" {
  name        = "${var.name}-eks-sg"
  description = "EKS Worker/Service Security Group"
  vpc_id      = var.vpc_id

  # ALB에서 오는 트래픽 허용 (HTTP, HTTPS)
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

  # ALB에서 오는 트래픽 허용 (Map API: 3000)
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  # ALB에서 오는 트래픽 허용 (Weather API: 3001)
  ingress {
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # EKS 노드/파드 내부 통신 허용 (ClusterIP 서비스 등)
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    self            = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-eks-sg" }
}
