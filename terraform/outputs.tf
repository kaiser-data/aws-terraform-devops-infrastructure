# Output definitions for Ansible inventory and SSH configuration

output "frontend_public_ip" {
  description = "Public IP of the frontend instance"
  value       = aws_instance.frontend.public_ip
}

output "frontend_private_ip" {
  description = "Private IP of the frontend instance"
  value       = aws_instance.frontend.private_ip
}

output "backend_private_ip" {
  description = "Private IP of the backend instance"
  value       = aws_instance.backend.private_ip
}

output "database_private_ip" {
  description = "Private IP of the database instance"
  value       = aws_instance.database.private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.time_circuit.id
}

output "frontend_instance_id" {
  description = "ID of the frontend instance"
  value       = aws_instance.frontend.id
}

output "backend_instance_id" {
  description = "ID of the backend instance"
  value       = aws_instance.backend.id
}

output "database_instance_id" {
  description = "ID of the database instance"
  value       = aws_instance.database.id
}

output "ansible_setup_complete" {
  description = "Next steps for Ansible deployment"
  value       = <<-EOT

    ✅ Infrastructure deployed successfully!

    Frontend Public IP: ${aws_instance.frontend.public_ip}
    Backend Private IP: ${aws_instance.backend.private_ip}
    Database Private IP: ${aws_instance.database.private_ip}

    Next steps:
    1. Update SSH config: cat ../ansible/ssh_config >> ~/.ssh/config
    2. Update inventory: cd ../ansible && ./update-inventory.sh
    3. Test connectivity: ansible all -m ping
    4. Install Docker: ansible-playbook playbooks/install-docker.yml
    5. Deploy apps: ansible-playbook playbooks/deploy-all.yml

    Access your application:
    - Vote app: http://${aws_instance.frontend.public_ip}:80
    - Result app: http://${aws_instance.frontend.public_ip}:5001
  EOT
}
