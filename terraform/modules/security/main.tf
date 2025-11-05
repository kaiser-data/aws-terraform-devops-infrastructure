# Security Module
# Security groups for 3-tier voting app architecture

# Frontend Security Group (Public-facing)
resource "aws_security_group" "frontend" {
  name        = "${var.environment}-frontend-sg"
  description = "Security group for frontend instances"
  vpc_id      = var.vpc_id

  # SSH access (restricted to admin IP)
  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
  }

  # HTTP access (public)
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access (public)
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Result app port
  ingress {
    description = "Result app port"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    { Name = "${var.environment}-frontend-sg" }
  )
}

# Backend Security Group (Private - Redis + Worker)
resource "aws_security_group" "backend" {
  name        = "${var.environment}-backend-sg"
  description = "Security group for backend instances"
  vpc_id      = var.vpc_id

  # SSH from frontend (bastion)
  ingress {
    description     = "SSH from frontend"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  # Redis from frontend
  ingress {
    description     = "Redis from frontend"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  # Allow all outbound
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    { Name = "${var.environment}-backend-sg" }
  )
}

# Database Security Group (Private - PostgreSQL)
resource "aws_security_group" "database" {
  name        = "${var.environment}-database-sg"
  description = "Security group for database instances"
  vpc_id      = var.vpc_id

  # SSH from frontend (bastion)
  ingress {
    description     = "SSH from frontend"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  # PostgreSQL from backend (worker)
  ingress {
    description     = "PostgreSQL from backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  # PostgreSQL from frontend (result app)
  ingress {
    description     = "PostgreSQL from frontend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  # Allow all outbound
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    { Name = "${var.environment}-database-sg" }
  )
}
