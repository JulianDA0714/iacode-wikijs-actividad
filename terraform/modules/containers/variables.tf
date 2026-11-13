variable "project_name" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "ec2_security_group_id" {
  type = string
}

variable "postgres_endpoint" {
  type = string
}

variable "postgres_secret_arn" {
  type = string
}

variable "redis_endpoint" {
  type = string
}

variable "ami_id" {
  type    = string
  default = "ami-0df8a753693e6366d"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}