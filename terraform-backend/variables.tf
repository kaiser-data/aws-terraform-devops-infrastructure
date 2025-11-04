variable "aws_region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "bttf"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "shared"
}
