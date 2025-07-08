output "eks_cluster_name" {
  value = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "node_group_name" {
  value = aws_eks_node_group.this.node_group_name
}

output "node_role_arn" {
  value = aws_iam_role.eks_node.arn
}

output "eks_sg_id" {
  description = "EKS 클러스터 및 노드에 할당된 보안 그룹 ID"
  value       = var.eks_sg_id
}
