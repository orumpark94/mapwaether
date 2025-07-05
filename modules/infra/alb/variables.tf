variable "name" {
  description = "리소스 네임 prefix"
}
variable "vpc_id" {
  description = "ALB가 속할 VPC ID"
}
variable "public_subnet_ids" {
  description = "ALB가 배치될 퍼블릭 서브넷 ID 리스트"
  type        = list(string)
}
variable "alb_sg_id" {
  description = "ALB Security Group ID"
}
