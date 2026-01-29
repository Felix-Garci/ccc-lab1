variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "project_name" {
  description = "Name of the project (used for resource naming and tagging)"
  type        = string
}

variable "availability_zone" {
  description = "Zona de disponibilidad para la subnet publica"
  type        = string
  default     = "us-east-1a"
}

