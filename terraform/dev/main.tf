locals {
  dev_config = yamldecode(file("${path.module}/../../config/dev.yml"))
  s3_bucket  = local.dev_config.s3_bucket
}

provider "aws" {
  region  = local.dev_config.region
  profile = local.dev_config.aws_profile
}

module "github_oidc" {
  source        = "../modules/github_oidc_role"
  github_repo   = local.dev_config.github_repo
  role_name     = "dev-github-actions-role"
  assume_branch = "main"

  policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "ec2:DescribeInstances",
      ]
      Resource = ["*"]
    }
  ]
}

module "iam" {
  source      = "../modules/iam"
  name_prefix = local.dev_config.environment
}

module "vpc" {
  source               = "../modules/vpc"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  availability_zones   = ["ap-northeast-1a", "ap-northeast-1c"]
  name_prefix          = local.dev_config.environment
}

module "igw" {
  source      = "../modules/igw"
  vpc_id      = module.vpc.vpc_id
  name_prefix = local.dev_config.environment
}

module "bastion" {
  source               = "../modules/bastion_ansible"
  name_prefix          = local.dev_config.environment
  ami_id               = local.dev_config.ami_id
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.public_subnet_ids[0]
  key_name             = local.dev_config.key_name
  sg_id                = module.sg.bastion_sg_id
  iam_instance_profile = module.iam.bastion_instance_profile_name
  s3_bucket            = local.s3_bucket
}

module "nat" {
  source                = "../modules/nat"
  name_prefix           = local.dev_config.environment
  ami_id                = local.dev_config.ami_id
  instance_type         = local.dev_config.instance_type
  vpc_id                = module.vpc.vpc_id
  public_subnet_id      = module.vpc.public_subnet_ids[0]
  instance_profile_name = module.iam.nat_instance_profile_name
  sg_id                 = module.sg.nat_sg_id
  key_name              = local.dev_config.key_name
}

module "route" {
  source             = "../modules/route"
  name_prefix        = local.dev_config.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  nat_eni_id         = module.nat.nat_eni_id
  vpc_cidr_block     = module.vpc.vpc_cidr_block
  igw_id             = module.igw.igw_id
  #  depends_on         = [module.nat, module.igw, module.vpc]
}

module "sg" {
  source         = "../modules/sg"
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
  name_prefix    = local.dev_config.environment
  nlb_cidr_block = "10.0.0.0/16" # NLBがあるサブネットに合わせて調整
  bastion_src_ip = local.dev_config.bastion_src_ip
  lambda_sg_id   = module.sg.lambda_sg_id
}

module "rtsp_asg" {
  source                = "../modules/rtsp_asg"
  name_prefix           = local.dev_config.environment
  ami_id                = local.dev_config.ami_id
  instance_type         = local.dev_config.instance_type
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_id     = module.sg.rtsp_ec2_sg_id
  instance_profile_name = module.iam.rtsp_profile_name
  min_size              = 1
  max_size              = 3
  desired_capacity      = 1
  key_name              = local.dev_config.key_name
  region                = local.dev_config.region
}

module "lambda_ec2_launch_ansible_trigger" {
  source                      = "../modules/lambda_ec2_launch_ansible_trigger"
  lambda_zip_path             = "../modules/lambda_ec2_launch_ansible_trigger/lambda_layer.zip"
  environment                 = local.dev_config.environment
  bastion_ssh_key_secret_name = "BASTION_SSH_KEY_SECRET"
  bastion_ssh_user            = "ec2-user"
  lambda_subnet_ids           = module.vpc.private_subnet_ids
  lambda_security_group_ids   = [module.sg.lambda_sg_id]
  s3_bucket                   = local.s3_bucket
}

## 循環参照回避、apply前に値が確定しない、Terraformの制約上、ここでresourceを定義
#resource "aws_security_group_rule" "bastion_allow_lambda" {
#  type                     = "ingress"
#  from_port                = 22
#  to_port                  = 22
#  protocol                 = "tcp"
#  security_group_id        = module.sg.bastion_sg_id
#  source_security_group_id = module.sg.lambda_sg_id
#  description              = "Allow SSH from Lambda to Bastion"
#}
