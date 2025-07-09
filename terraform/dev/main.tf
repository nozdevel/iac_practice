provider "aws" {
  region  = "ap-northeast-1"
  profile = var.aws_profile
}

module "iam" {
  source      = "../modules/iam"
  name_prefix = "dev"
}

module "vpc" {
  source               = "../modules/vpc"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  availability_zones   = ["ap-northeast-1a", "ap-northeast-1c"]
  name_prefix          = "dev"
}

module "bastion" {
  source      = "../modules/bastion_ansible"
  name_prefix = "dev"
  ami_id      = "ami-03598bf9d15814511" # AL2023
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.public_subnet_ids[0]
  key_name    = var.key_name
  sg_id       = module.sg.bastion_sg_id
}

module "nat" {
  source                 = "../modules/nat"
  name_prefix            = "dev"
  ami_id                 = "ami-03598bf9d15814511" # AL2023
  instance_type          = "t3.micro"
  vpc_id                 = module.vpc.vpc_id
  public_subnet_id       = module.vpc.public_subnet_ids[0] # 1つ目のpublic subnetに配置
  private_route_table_id = module.route.private_route_table_id
  instance_profile_name  = module.iam.instance_profile_name
  sg_id                  = module.sg.nat_sg_id
  key_name               = var.key_name
}

module "route" {
  source             = "../modules/route"
  name_prefix        = "dev"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  nat_eni_id         = module.nat.nat_eni_id
  vpc_cidr_block     = module.vpc.vpc_cidr_block
}

module "sg" {
  source         = "../modules/sg"
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
  name_prefix    = "dev"
  nlb_cidr_block = "10.0.0.0/16" # NLBがあるサブネットに合わせて調整
  bastion_src_ip = var.bastion_src_ip
}

module "rtsp_asg" {
  source                = "../modules/rtsp_asg"
  name_prefix           = "dev"
  ami_id                = "ami-03598bf9d15814511" # AL2023
  instance_type         = "t3.micro"
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_id     = module.sg.rtsp_ec2_sg_id
  instance_profile_name = module.iam.instance_profile_name
  min_size              = 1
  max_size              = 3
  desired_capacity      = 1
  key_name              = var.key_name
}

#module "nlb" {
#  source      = "../modules/nlb"
#  name_prefix = "dev"
#  subnet_ids  = module.vpc.private_subnet_ids
#  vpc_id      = module.vpc.vpc_id
#  asg_name    = module.rtsp_asg.asg_name
#}
