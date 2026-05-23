output "vpc_id" {
  description = "Created VPC ID."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Created public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "internet_gateway_id" {
  description = "Created internet gateway ID."
  value       = aws_internet_gateway.main.id
}
