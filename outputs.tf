output "frontend_public_ip" {
  description = "Public IP of clocktower-voting-frontend"
  value       = aws_instance.frontend.public_ip
}

output "frontend_private_ip" {
  description = "Private IP of frontend"
  value       = aws_instance.frontend.private_ip
}

output "backend_private_ip" {
  description = "Private IP of doc-lab-processor"
  value       = aws_instance.backend.private_ip
}

output "database_private_ip" {
  description = "Private IP of timeline-archive-db"
  value       = aws_instance.database.private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.time_circuit.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.townsquare_public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.lab_private.id
}
