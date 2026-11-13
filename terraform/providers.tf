provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "wikijs-actividad5"
      Environment = "academic"
      ManagedBy   = "Terraform"
    }
  }
}