module "EKS" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.23" # [lastest version - Source : https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest]

  name    = "infoline-cluster"
  kubernetes_version = "1.36" 

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.micro"] # diminution des coups pour l'ECF ( choisir une T3.modium pour une vrais prod)
  }
}
}
