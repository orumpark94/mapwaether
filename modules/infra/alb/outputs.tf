output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns" {
  description = "ALB DNS 이름"
  value       = aws_lb.this.dns_name
}

output "map_tg_arn" {
  description = "Map API Target Group ARN"
  value       = aws_lb_target_group.map.arn
}
