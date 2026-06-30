variable "lambda_handler" {
  type = string
}
variable "environment" {
  type = string
}
variable "db_endpoint" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "private_subnets" {
  type = list(string)
}