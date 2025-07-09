#frontend 용 s3 버킷
module "frontend_s3" {
  source      = "./modules/s3"
  bucket_name = var.s3_bucket_name
  region      = var.region
}

#terrafrom state 파일 저장 s3
terraform {
  backend "s3" {
    bucket = "mapweather-terraform"           # 만든 S3 버킷 이름
    key    = "terraform.tfstate"              # 저장될 state 파일 이름(폴더 포함 가능)
    region = "ap-northeast-2"                 # S3 버킷 리전
    encrypt = true
  }
}

module "vpc" {
  source              = "./modules/infra/vpc"
  name                = "mapweather"
  vpc_cidr            = "10.10.0.0/16"
  public_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]
  availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
}

module "security" {
  source = "./modules/infra/security"
  name   = var.name
  vpc_id = module.vpc.vpc_id
}

module "alb" {
  source             = "./modules/infra/alb"
  name               = "mapweather"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
}

module "eks" {
  source             = "./modules/infra/eks"
  name               = "mapweather"
  region             = "ap-northeast-2"

  # -- VPC/SG/서브넷 등은 위에서 만든 모듈 output값을 사용 --
  eks_sg_id          = module.security.eks_sg_id       # ← SG를 security 모듈에서 output한 경우
  private_subnet_ids = module.vpc.private_subnet_ids   # ← VPC 모듈 output
  node_instance_type = "t3.medium"
  node_desired_size  = 2
  node_max_size      = 3
  node_min_size      = 1
  cluster_name       = "mapweather-eks-cluster"       # EKS 클러스터 이름
}
