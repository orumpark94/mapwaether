provider "aws" {
  region = var.region
}

# (0) 클러스터 정보를 읽기 위한 data 리소스 추가
data "aws_eks_cluster" "this" {
  name = "${var.name}-eks-cluster"

  depends_on = [aws_eks_cluster.this] # 클러스터 생성 이후에 조회하도록 명시
}


# (1) EKS 클러스터용 IAM 역할
resource "aws_iam_role" "eks_cluster" {
  name = "${var.name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# (2) EKS Node용 IAM 역할
resource "aws_iam_role" "eks_node" {
  name = "${var.name}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# (2.5) EKS Node용 AMI 조회
data "aws_ami" "eks_worker" {
  most_recent = true
  owners      = ["602401143452"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.28-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_iam_instance_profile" "eks_node" {
  name = "${var.name}-eks-node-profile"
  role = aws_iam_role.eks_node.name
}


# (2.6) Launch Template 생성
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = var.node_instance_type
   

user_data = base64encode(<<EOF
#!/bin/bash
/etc/eks/bootstrap.sh ${data.aws_eks_cluster.this.name} \
  --apiserver-endpoint ${data.aws_eks_cluster.this.endpoint} \
  --b64-cluster-ca ${data.aws_eks_cluster.this.certificate_authority[0].data}
EOF
)

  network_interfaces {
    security_groups             = [var.eks_sg_id]
    associate_public_ip_address = false
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name}-eks-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# (3) EKS 클러스터 생성 (기본 depends_on만 유지)
resource "aws_eks_cluster" "this" {
  name     = "${var.name}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [var.eks_sg_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role.eks_cluster
  ]
}

# (4) EKS Node Group 생성
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-node-group"
  subnet_ids      = var.private_subnet_ids
  node_role_arn = aws_iam_role.eks_node.arn

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  capacity_type = "ON_DEMAND"

  depends_on = [aws_iam_role.eks_node]
}

# (5) 클러스터 이름 SSM에 저장
resource "aws_ssm_parameter" "eks_cluster_name" {
  name      = "/mapweather/eks-cluster-name"
  type      = "String"
  value     = aws_eks_cluster.this.name
  overwrite = true
}

