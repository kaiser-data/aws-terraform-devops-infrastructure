# Ubuntu 22.04 LTS (Jammy) AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Frontend (Vote + Result) - public
resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.frontend_instance_type
  subnet_id                   = aws_subnet.townsquare_public.id
  vpc_security_group_ids      = [aws_security_group.sg_frontend.id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  tags = {
    Name  = "clocktower-voting-frontend"
    Role  = "frontend"
    Owner = "Marty McFly"
  }
}

# Backend (Worker + Redis) - private
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.backend_instance_type
  subnet_id              = aws_subnet.lab_private.id
  vpc_security_group_ids = [aws_security_group.sg_backend.id]
  key_name               = var.key_pair_name

  tags = {
    Name  = "doc-lab-processor"
    Role  = "backend"
    Owner = "Marty McFly"
  }
}

# Database (PostgreSQL) - private
resource "aws_instance" "database" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.db_instance_type
  subnet_id              = aws_subnet.lab_private.id
  vpc_security_group_ids = [aws_security_group.sg_database.id]
  key_name               = var.key_pair_name

  tags = {
    Name  = "timeline-archive-db"
    Role  = "database"
    Owner = "Marty McFly"
  }
}
