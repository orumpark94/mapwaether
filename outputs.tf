
output "eks_cluster_name" {
  value = module.eks.eks_cluster_name
}

output "node_role_arn" {
  value = module.eks.node_role_arn
}

output "alb_dns" {
  description = "ALB DNS 이름"
  value       = module.alb.alb_dns
}
