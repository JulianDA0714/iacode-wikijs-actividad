variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "Perfil de AWS CLI"
  type        = string
  default     = "terraform-wikijs"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "wikijs-actividad5"
}