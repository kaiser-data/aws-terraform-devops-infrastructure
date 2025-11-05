# VPC Module
# Reusable VPC with public/private subnets, NAT gateway, and routing

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    var.tags,
    { Name = "${var.environment}-vpc" }
  )
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_az
  map_public_ip_on_launch = true
  tags = merge(
    var.tags,
    { Name = "${var.environment}-public-subnet" }
  )
}

# Private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_az
  tags = merge(
    var.tags,
    { Name = "${var.environment}-private-subnet" }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    { Name = "${var.environment}-igw" }
  )
}

# EIP for NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  tags = merge(
    var.tags,
    { Name = "${var.environment}-nat-eip" }
  )
}

# NAT Gateway (for private subnet egress)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = merge(
    var.tags,
    { Name = "${var.environment}-nat-gateway" }
  )
  depends_on = [aws_internet_gateway.main]
}

# Public route table → Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(
    var.tags,
    { Name = "${var.environment}-public-rt" }
  )
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

# Private route table → NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = merge(
    var.tags,
    { Name = "${var.environment}-private-rt" }
  )
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private.id
}
