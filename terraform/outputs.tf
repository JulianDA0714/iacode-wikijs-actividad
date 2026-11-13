output "aws_account_id" {
  description = "Cuenta AWS utilizada"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "Region utilizada"
  value       = data.aws_region.current.name
}


output "wikijs_public_ip" {
  description = "IP publica de la instancia Wiki.js"
  value       = module.containers.public_ip
}

output "wikijs_public_dns" {
  description = "DNS publico de la instancia Wiki.js"
  value       = module.containers.public_dns
}

output "wikijs_instance_id" {
  description = "Identificador de EC2"
  value       = module.containers.instance_id
}
