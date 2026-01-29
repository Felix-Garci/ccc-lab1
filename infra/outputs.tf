output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "instance_public_ip" {
  description = "IP Publica de la instancia EC2"
  value       = aws_instance.web_server.public_ip
}

output "website_url" {
  description = "Enlace directo al servidor web"
  value       = "http://${aws_instance.web_server.public_ip}"
}
