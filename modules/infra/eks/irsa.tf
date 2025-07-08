# 1. EKS 클러스터 정보 로딩 (module.eks.eks_cluster_name이 이미 output 되어 있음)
data "aws_eks_cluster" "irsa" {
  name = module.eks.eks_cluster_name

  # EKS 클러스터가 생성 완료된 후 실행
  depends_on = [module.eks]
}

# 2. OIDC 공급자 생성 (EKS 클러스터가 있어야 URL 조회 가능)
resource "aws_iam_openid_connect_provider" "this" {
  url             = data.aws_eks_cluster.irsa.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecd5c0f6"]

  depends_on = [data.aws_eks_cluster.irsa]
}

# 3. IRSA 역할 생성 (OIDC 공급자 생성 이후)
resource "aws_iam_role" "irsa" {
  name = "mapweather-map-api-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.this.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.irsa.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:default:map-api-sa"
        }
      }
    }]
  })

  depends_on = [aws_iam_openid_connect_provider.this]
}

# 4. AmazonSSMFullAccess 정책 연결 (IAM Role 생성 이후)
resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"

  depends_on = [aws_iam_role.irsa]
}
