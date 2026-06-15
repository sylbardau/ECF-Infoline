#appel des modules de l'infra INFOLINE

module "VPC" {
  source = "./VPC"

}

module "EKS" {
  source = "./EKS"
  
#ajout des variables
  vpc_id          = module.VPC.vpc_id
  private_subnets = module.VPC.private_subnets

}
