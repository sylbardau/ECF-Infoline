module "EKS" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.24" # [Source : https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest]

  name               = "infoline-cluster"
  kubernetes_version = "1.36"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  endpoint_public_access  = true
  endpoint_private_access = true

  compute_config = {
   enabled = false
  }

  addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent    = true
      before_compute = true
    }
    coredns = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    default = {
      kubernetes_version = "1.36"
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.small"] # diminution des couts pour l'ECF ( choisir une T3.medium pour une vrais prod)

      iam_role_additional_policies = {
       AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }
}
