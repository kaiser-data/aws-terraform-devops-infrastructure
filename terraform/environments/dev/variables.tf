variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "ap-northeast-2"
}

variable "key_pair_name" {
  description = "AWS EC2 key pair for SSH access"
  type        = string
  default     = "martin-ap-northeast-2-key"
}

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "marty"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "az_public" {
  description = "AZ for public subnet"
  type        = string
  default     = "ap-northeast-2a"
}

variable "az_private" {
  description = "AZ for private subnet"
  type        = string
  default     = "ap-northeast-2a"
}

variable "frontend_instance_type" {
  description = "Instance type for frontend EC2 (Vote + Result apps)"
  type        = string
  default     = "t3.micro"
}

variable "backend_instance_type" {
  description = "Instance type for backend EC2 (Redis + Worker)"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for database EC2 (PostgreSQL)"
  type        = string
  default     = "t3.micro"
}

variable "my_ip" {
  description = "Your public IP address for SSH access (CIDR format: x.x.x.x/32)"
  type        = string
  sensitive   = true
}
