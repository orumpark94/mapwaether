output "alb_sg_id" {
  description = "ALB용 Security Group ID"
  value       = aws_security_group.alb.id
}

output "eks_sg_id" {
  description = "EKS Node/Service용 Security Group ID"
  value       = aws_security_group.eks.id
}
