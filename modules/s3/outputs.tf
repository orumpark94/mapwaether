output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.this.bucket
}

output "website_endpoint" {
  description = "S3 static website endpoint"
  value       = "http://${aws_s3_bucket.this.bucket}.s3-website.${var.region}.amazonaws.com"
}
