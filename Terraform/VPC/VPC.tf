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

resource "aws_security_group" "sg_eks_nodes" {
  name        = "sg_eks_nodes"
  description = "Groupe de securite pour les nodes EKS"
  vpc_id      = module.VPC.vpc_id

  # Communication entre nodes du cluster
  ingress {
    description = "Trafic interne entre nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Accès depuis le control plane EKS
  ingress {
    description = "Kubelet depuis le control plane"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-eks-nodes"
  }
}