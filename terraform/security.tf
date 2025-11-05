resource "aws_security_group" "sg_frontend" {
  name   = "bttf-frontend-sg"
  vpc_id = aws_vpc.time_circuit.id

  # SSH access restricted to your IP only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Result app port
  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Node Exporter
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "bttf-frontend-sg"
    Owner = "Marty McFly"
  }
}

# Backend Security Group (Redis + Worker)
resource "aws_security_group" "sg_backend" {
  name   = "bttf-backend-sg"
  vpc_id = aws_vpc.time_circuit.id

  # SSH from frontend (bastion host)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_frontend.id]
  }

  # Redis port from frontend (vote app needs to write votes)
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_frontend.id]
  }

  # Allow all outbound (worker needs to reach postgres + internet for packages)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "bttf-backend-sg"
    Owner = "Marty McFly"
  }
}

# Database Security Group (PostgreSQL)
resource "aws_security_group" "sg_database" {
  name   = "bttf-database-sg"
  vpc_id = aws_vpc.time_circuit.id

  # SSH from frontend (bastion host)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_frontend.id]
  }

  # PostgreSQL from backend (worker writes votes to database)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_backend.id]
  }

  # PostgreSQL from frontend (result app reads votes from database)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_frontend.id]
  }

  # Allow outbound for package updates
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "bttf-database-sg"
    Owner = "Marty McFly"
  }
}
