# Security group dédié au RDS
resource "aws_security_group" "rds" {
  name        = "infoline-rds-sg" # Security group pour le RDS Infoline
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL depuis le VPC"
    from_port   = 5432
    to_port     = 35432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # uniquement depuis le VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Subnet group pour placer le RDS dans les subnets privés
resource "aws_db_subnet_group" "rds" {
  name       = "infoline-rds-subnet-group"
  subnet_ids = var.private_subnets
}

module "RDS" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.2.0" # [lastet version - Source : https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest]

  identifier = "infoline-db" 

  instance_class = "db.t3.micro"
  engine               = "postgres"
  engine_version       = "15"        
  major_engine_version = "15"
  family               = "postgres15"

  
  db_name  = "infolinedb"
  username = "admininfoline"
  
  manage_master_user_password = true 

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.rds.name

  # Sauvegardes
  backup_retention_period = 7     # 7 jours de rétention
  skip_final_snapshot     = false # snapshot avant suppression
  final_snapshot_identifier_prefix = "infoline-db-final"

  # Pas de Multi-AZ pour limiter les coûts (à activer en prod)
  multi_az = false
}
