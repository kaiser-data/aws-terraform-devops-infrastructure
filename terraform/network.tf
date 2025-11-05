# VPC
resource "aws_vpc" "time_circuit" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "time-circuit-vpc", Owner = "Marty McFly" }
}

# Public subnet (Frontend)
resource "aws_subnet" "townsquare_public" {
  vpc_id                  = aws_vpc.time_circuit.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az_public
  map_public_ip_on_launch = true
  tags                    = { Name = "townsquare-subnet-public", Owner = "Marty McFly" }
}

# Private subnet (Backend + DB)
resource "aws_subnet" "lab_private" {
  vpc_id            = aws_vpc.time_circuit.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.az_private
  tags              = { Name = "lab-subnet-private", Owner = "Marty McFly" }
}

# Internet Gateway (Flux)
resource "aws_internet_gateway" "flux_gateway" {
  vpc_id = aws_vpc.time_circuit.id
  tags   = { Name = "flux-gateway", Owner = "Marty McFly" }
}

# EIP for NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "nat-eip", Owner = "Marty McFly" }
}

# NAT Gateway (for private egress)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.townsquare_public.id
  tags          = { Name = "nat-gateway", Owner = "Marty McFly" }
  depends_on    = [aws_internet_gateway.flux_gateway]
}

# Public route table → IGW
resource "aws_route_table" "timeline_public_rt" {
  vpc_id = aws_vpc.time_circuit.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.flux_gateway.id
  }
  tags = { Name = "timeline-public-rt", Owner = "Marty McFly" }
}

resource "aws_route_table_association" "assoc_public" {
  route_table_id = aws_route_table.timeline_public_rt.id
  subnet_id      = aws_subnet.townsquare_public.id
}

# Private route table → NAT
resource "aws_route_table" "timeline_private_rt" {
  vpc_id = aws_vpc.time_circuit.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "timeline-private-rt", Owner = "Marty McFly" }
}

resource "aws_route_table_association" "assoc_private" {
  route_table_id = aws_route_table.timeline_private_rt.id
  subnet_id      = aws_subnet.lab_private.id
}
