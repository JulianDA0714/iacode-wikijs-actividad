data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
}


module "database" {
  source = "./modules/database"

  project_name            = var.project_name
  private_subnet_ids      = module.networking.private_subnet_ids
  rds_security_group_id   = module.networking.rds_security_group_id
  redis_security_group_id = module.networking.redis_security_group_id
}


module "containers" {
  source = "./modules/containers"

  project_name          = var.project_name
  public_subnet_id      = module.networking.public_subnet_id
  ec2_security_group_id = module.networking.ec2_security_group_id

  postgres_endpoint   = module.database.postgres_endpoint
  postgres_secret_arn = module.database.postgres_secret_arn
  redis_endpoint      = module.database.redis_endpoint
}
