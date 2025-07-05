variable "s3_bucket_name" {
  description = "S3 버킷 이름"
  type        = string
  default     = "map-weather-seraching"  # (원하는 이름으로)
}

variable "name" {
  description = "프로젝트 또는 서비스 식별용 prefix"
  type        = string
  default     = "mapweather"   # ← 이렇게 default 값을 줌
}
