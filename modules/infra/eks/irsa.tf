
# (2) IAM OIDC 공급자 생성 (존재하지 않으면 새로 생성됨)
resource "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecd5c0f6"]
}

# (3) 기존 Role(mapweather-map-api-irsa-role)의 신뢰 정책을 OIDC 방식으로 업데이트
resource "null_resource" "update_irsa_trust_policy" {
  provisioner "local-exec" {
    command = <<EOT
cat <<EOF > assume-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.this.arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:default:map-api-sa"
        }
      }
    }
  ]
}
EOF

aws iam update-assume-role-policy \
  --role-name mapweather-map-api-irsa-role \
  --policy-document file://assume-policy.json
EOT
  }

  triggers = {
    oidc = aws_iam_openid_connect_provider.this.arn
  }

  depends_on = [aws_iam_openid_connect_provider.this]
}
