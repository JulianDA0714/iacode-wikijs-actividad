terraform {
  backend "s3" {
    bucket       = "wikijs-terraform-state-722861101950"
    key          = "actividad6/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}