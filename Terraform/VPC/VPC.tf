module "VPC" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6.1" # [lastet version - Source : https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest]

  name = "infoline-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-3a", "eu-west-3b"] # pour la haute disponibilité
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # budget limité : une seule NAT gateway
}
