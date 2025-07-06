variable "name" {
  description = "리소스 prefix"
}

variable "region" {
  description = "AWS 리전"
}

variable "private_subnet_ids" {
  description = "EKS 워커노드 프라이빗 서브넷 리스트"
  type        = list(string)
}

variable "eks_sg_id" {
  description = "EKS에 붙일 보안그룹 ID"
  type        = string
}


variable "node_instance_type" {
  description = "워커노드 인스턴스 타입"
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "노드그룹 디폴트 개수"
  default     = 2
}

variable "node_max_size" {
  description = "노드그룹 최대 개수"
  default     = 3
}

variable "node_min_size" {
  description = "노드그룹 최소 개수"
  default     = 1
}

# variables.tf
variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}



