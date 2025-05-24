# VPC Module Configuration
module "vpc" {
  source = "./modules/vpc"

  aws_region            = var.aws_region
  vpc_cidr              = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  availability_zone_1   = var.availability_zone_1
  availability_zone_2   = var.availability_zone_2
  my_ip                 = var.my_ip
  app_private_ip        = var.app_private_ip
}

# EC2 Module Configuration
module "ec2" {
  source            = "./modules/ec2"
  vpc_id            = module.vpc.vpc_id
  key_name          = var.key_name
  security_group_id = module.vpc.security_group_id
  app_private_ip    = var.app_private_ip
  dockerhub_user   = var.dockerhub_user
  image_tag        = var.image_tag
  public_subnet_id = module.vpc.public_subnet_1_id
}
