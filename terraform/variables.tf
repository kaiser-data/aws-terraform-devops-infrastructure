# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "my_ip" {
  description = "Your public IP for SSH access (CIDR format)"
  type        = string
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "az_public" {
  description = "Availability zone for public subnet"
  type        = string
  default     = "ap-northeast-2a"
}

variable "az_private" {
  description = "Availability zone for private subnet"
  type        = string
  default     = "ap-northeast-2a"
}

# Instance Types
variable "frontend_instance_type" {
  description = "EC2 instance type for frontend"
  type        = string
  default     = "t3.micro"
}

variable "backend_instance_type" {
  description = "EC2 instance type for backend"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "EC2 instance type for database"
  type        = string
  default     = "t3.micro"
}
