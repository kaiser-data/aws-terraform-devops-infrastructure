# VPC Module

Reusable Terraform module for creating a VPC with public and private subnets.

## Features

- VPC with custom CIDR
- Public subnet with Internet Gateway
- Private subnet with NAT Gateway
- Proper route tables for public and private subnets
- DNS support enabled
- Environment-based naming and tagging

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  environment          = "dev"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  public_az           = "ap-northeast-2a"
  private_az          = "ap-northeast-2c"

  tags = {
    Project     = "voting-app"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_cidr | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_cidr | CIDR block for public subnet | `string` | `"10.0.1.0/24"` | no |
| private_subnet_cidr | CIDR block for private subnet | `string` | `"10.0.2.0/24"` | no |
| public_az | Availability zone for public subnet | `string` | n/a | yes |
| private_az | Availability zone for private subnet | `string` | n/a | yes |
| tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| public_subnet_id | ID of the public subnet |
| private_subnet_id | ID of the private subnet |
| internet_gateway_id | ID of the Internet Gateway |
| nat_gateway_id | ID of the NAT Gateway |
| public_route_table_id | ID of the public route table |
| private_route_table_id | ID of the private route table |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  VPC (10.0.0.0/16)                                      │
│                                                          │
│  ┌────────────────────┐      ┌────────────────────┐   │
│  │ Public Subnet      │      │ Private Subnet     │   │
│  │ (10.0.1.0/24)      │      │ (10.0.2.0/24)      │   │
│  │                    │      │                    │   │
│  │  ┌──────────┐      │      │  ┌──────────┐     │   │
│  │  │   EC2    │      │      │  │   EC2    │     │   │
│  │  │Frontend  │      │      │  │ Backend  │     │   │
│  │  └────┬─────┘      │      │  └────┬─────┘     │   │
│  │       │            │      │       │           │   │
│  └───────┼────────────┘      └───────┼───────────┘   │
│          │                           │               │
│          │                           │               │
│     ┌────▼─────┐                ┌────▼─────┐        │
│     │   IGW    │                │   NAT    │        │
│     └────┬─────┘                │ Gateway  │        │
│          │                      └────┬─────┘        │
└──────────┼───────────────────────────┼──────────────┘
           │                           │
           ▼                           ▼
      Internet                    Internet
```

## Notes

- NAT Gateway incurs AWS costs
- EIP is automatically allocated for NAT Gateway
- DNS resolution is enabled by default
- All resources are tagged with environment name
