data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "null_resource" "update_irsa_trust_policy" {
  provisioner "local-exec" {
    command = <<EOT
aws iam update-assume-role-policy \
  --role-name mapweather-map-api-irsa-role \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "${data.aws_iam_openid_connect_provider.this.arn}"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:default:map-api-sa"
          }
        }
      }
    ]
  }'
EOT
  }

  triggers = {
    oidc = data.aws_iam_openid_connect_provider.this.arn
  }

  depends_on = [data.aws_eks_cluster.this]
}

