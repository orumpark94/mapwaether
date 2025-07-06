provider "aws" {
  region = var.region
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
    values = ["amazon-eks-node-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# (2.6) Launch Template 생성
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = var.node_instance_type

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

# ✅ 삭제 순서 강제용 null_resource (NodeGroup → Cluster)
resource "null_resource" "delete_order_block" {
  depends_on = [aws_eks_node_group.this]
}

# (3) EKS 클러스터 생성
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
    aws_iam_role.eks_cluster,
    aws_launch_template.eks_nodes,
    null_resource.delete_order_block  # ✅ 삭제 시 NodeGroup보다 늦게 삭제됨
  ]
}

# (4) EKS Node Group 생성
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
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
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

# (6) ServiceAccount 적용
resource "null_resource" "create_sa" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/map-api-sa.yaml"
  }

  depends_on = [aws_eks_cluster.this, aws_eks_node_group.this]
}

# (7) aws-auth ConfigMap 적용
resource "null_resource" "apply_aws_auth" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/aws-auth.yaml"
  }

  depends_on = [aws_eks_node_group.this]
}
