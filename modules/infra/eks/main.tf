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

# (2) Launch Template 생성 (여기서 SG 단일화!)
resource "aws_launch_template" "eks" {
  name_prefix   = "${var.name}-eks-node-"
  image_id      = data.aws_ami.eks_worker.id  # (위에서 조회한 최신 EKS 워커 AMI 사용)
  instance_type = var.node_instance_type
  vpc_security_group_ids = [aws_security_group.eks.id]  # 🔥 SG 단일화!
}

# (3) EKS 클러스터 (기존과 동일, 내가 만든 SG만 할당)
resource "aws_eks_cluster" "this" {
  name     = "${var.name}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.eks.id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  depends_on = [aws_iam_role.eks_cluster]
}

# (4) IAM 등 기타 리소스 (변경 없음, 기존대로 사용)
# ... 중략 (생략) ...

# (5) EKS Node Group (launch_template 적용)
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

  ami_type = "AL2_x86_64"

  depends_on = [aws_iam_role.eks_node]
}

resource "aws_ssm_parameter" "eks_cluster_name" {
  name  = "/mapweather/eks-cluster-name"
  type  = "String"
  value = aws_eks_cluster.this.name
}

