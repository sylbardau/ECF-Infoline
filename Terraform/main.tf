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

module "RDS" {
  source = "./RDS"

  #ajout des variables
  vpc_id          = module.VPC.vpc_id
  private_subnets = module.VPC.private_subnets
}

module "lambda" {
  source = "./lambda"

  #ajout des variables
  lambda_handler  = "com.infoline.LoginHandler::handleRequest" # [À PERSONNALISER PAR L'EQUIPE DE DEV]
  environment     = var.environment
  db_endpoint     = module.RDS.db_instance_endpoint
  vpc_id          = module.VPC.vpc_id
  private_subnets = module.VPC.private_subnets
}
