# -------- VPC --------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16" # This means: our entire VPC has a lot of IPs, approx 65k or slightly moore
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# -------- Public Subnets --------
# Subnet 1 in eu-central-1a
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24" # About 256 IPs
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-1"
  }
}

# Subnet 2 in eu-central-1b
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24" # Next block, 256 IPs
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-2"
  }
}


# -------- Internet Gateway --------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# -------- Route Table --------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Default route: anything 0.0.0.0/0 goes through IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# -------- Route Table Association --------
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

