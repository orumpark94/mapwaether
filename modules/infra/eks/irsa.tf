############################################
# IRSA: 기존 IAM Role을 참조해서 정책만 연결
############################################

# 1. 이미 존재하는 IRSA IAM Role을 참조
data "aws_iam_role" "map_api_irsa" {
  name = "${var.name}-map-api-irsa-role"
}

# 2. AmazonSSMReadOnlyAccess 정책을 해당 Role에 연결
resource "aws_iam_role_policy_attachment" "map_api_irsa_ssm" {
  role       = data.aws_iam_role.map_api_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}
