resource "local_file" "deployment_info" {
  content = <<EOT
Back to the Future – Voting Infra
=================================
Region: ${var.aws_region}
Owner:  Marty McFly

Frontend (Clock Tower)
----------------------
Name:       ${aws_instance.frontend.tags["Name"]}
Public IP:  ${aws_instance.frontend.public_ip}
Private IP: ${aws_instance.frontend.private_ip}
SG:         ${aws_security_group.sg_frontend.id}

Backend (Doc's Lab)
-------------------
Name:       ${aws_instance.backend.tags["Name"]}
Private IP: ${aws_instance.backend.private_ip}
SG:         ${aws_security_group.sg_backend.id}

Database (Timeline Archive)
---------------------------
Name:       ${aws_instance.database.tags["Name"]}
Private IP: ${aws_instance.database.private_ip}
SG:         ${aws_security_group.sg_database.id}

VPC / Subnets
-------------
VPC:                ${aws_vpc.time_circuit.id}
Public Subnet:      ${aws_subnet.townsquare_public.id}
Private Subnet:     ${aws_subnet.lab_private.id}

SSH to Frontend:
ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.frontend.public_ip}

Notes:
- Private instances have outbound internet via NAT (package installs ok).
- Redis (6379) allowed from Frontend and Backend SGs.
- Postgres (5432) allowed from Frontend (Result) and Backend (Worker).
EOT

  filename = "${path.module}/deployment-info.txt"
}
