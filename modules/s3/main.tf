resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = var.bucket_name
  }
}

# 정적 웹사이트 호스팅 설정
resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# 퍼블릭 접근을 일부 허용 (정적 웹 접근만 가능)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 누구나 GetObject는 허용 (정적 웹 접근을 위한 최소 공개)
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_public_read.json
}

data "aws_iam_policy_document" "allow_public_read" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    effect = "Allow"
  }
}

# SSM에 웹사이트 엔드포인트 저장
resource "aws_ssm_parameter" "frontend_endpoint" {
  name  = "frontend-address"
  type  = "String"
  value = aws_s3_bucket.this.website_endpoint
}

# 출력
output "frontend_website_endpoint" {
  value = aws_s3_bucket.this.website_endpoint
}
