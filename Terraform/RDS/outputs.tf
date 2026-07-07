output "db_instance_endpoint" {
  value = module.RDS.db_instance_endpoint
}

output "db_instance_master_user_secret_arn" {
  value     = module.RDS.db_instance_master_user_secret_arn
  sensitive = true
}