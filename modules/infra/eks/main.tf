provider "aws" {
  region = var.region
}

# (1) EKS 전용 최신 AMI 조회 (data 소스)
data "aws_ami" "eks_worker" {
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS 공식 계정

  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# (2) IAM 역할 - EKS 클러스터용
resource "aws_iam_role" "eks_cluster" {
  name = "${var.name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [ {
      Action = "sts:AssumeRole",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    } ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# (3) IAM 역할 - EKS Node용
resource "aws_iam_role" "eks_node" {
  name = "${var.name}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [ {
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    } ]
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

# ✅ (3-1) 추가: IAM 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "eks_node_profile" {
  name = "${var.name}-eks-node-profile"
  role = aws_iam_role.eks_node.name
}

# (4) Launch Template 생성
resource "aws_launch_template" "eks" {
  name_prefix   = "${var.name}-eks-node-"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = var.node_instance_type
  vpc_security_group_ids = [var.eks_sg_id]

  # ✅ 추가: IAM 인스턴스 프로파일 연결
  iam_instance_profile {
    name = aws_iam_instance_profile.eks_node_profile.name
  }
}

# (5) EKS 클러스터 생성
resource "aws_eks_cluster" "this" {
  name     = "${var.name}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [var.eks_sg_id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  depends_on = [aws_iam_role.eks_cluster]
}

# (6) EKS Node Group 생성
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  launch_template {
    id      = aws_launch_template.eks.id
    version = "$Latest"
  }

  ami_type = "CUSTOM"

  depends_on = [aws_iam_role.eks_node]
}

# (7) 클러스터 이름 SSM에 저장
resource "aws_ssm_parameter" "eks_cluster_name" {
  name  = "/mapweather/eks-cluster-name"
  type  = "String"
  value = aws_eks_cluster.this.name
}

# (8) aws-auth ConfigMap 적용
data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.this.name
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_node.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this,
    aws_launch_template.eks
  ]
}
