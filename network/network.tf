resource "aws_vpc" "main" {
  cidr_block           = "${var.cidr_block}.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-igw"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "main" {
  count                   = var.subnetting
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.cidr_block}.${count.index}.0/24"
  availability_zone_id    = count.index < var.subnetting / 2 ? data.aws_availability_zones.available.zone_ids[0] : data.aws_availability_zones.available.zone_ids[1]
  map_public_ip_on_launch = count.index % 2 == 0 ? true : false
  tags = var.eks == false ? {
    Name = count.index % 2 == 0 ? "${var.name}-public-subnet-${count.index}" : "${var.name}-private-subnet-${count.index}"
    } : {
    Name                                            = count.index % 2 == 0 ? "${var.name}-public-subnet-${count.index}" : "${var.name}-private-subnet-${count.index}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = count.index % 2 == 0 ? 1 : null
    "kubernetes.io/role/internal_elb"               = count.index % 2 == 0 ? null : 1
  }
}

resource "aws_eip" "main" {
  count = var.subnetting > 1 && var.nat_gateway ? 1 : 0
  vpc   = true
  tags = {
    Name = "${var.name}-elastic-ip"
  }
  #Just available if a private subnet is created 
  depends_on = [
    aws_subnet.main[1]
  ]
}

resource "aws_nat_gateway" "main" {
  count         = var.subnetting > 1 && var.nat_gateway ? 1 : 0
  allocation_id = aws_eip.main[0].id
  subnet_id     = aws_subnet.main[0].id

  tags = {
    Name = "${var.name}-nat"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [
    aws_internet_gateway.main,
    aws_eip.main[0]
  ]
}
resource "aws_route_table" "main" {
  count  = var.subnetting > 1 && var.nat_gateway ? 2 : 1
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = count.index == 0 ? aws_internet_gateway.main.id : aws_nat_gateway.main[0].id
  }

  tags = {
    Name = count.index == 0 ? "${var.name}-public-rt" :  "${var.name}-private-rt"
  }
}

resource "aws_route_table_association" "main_public" {
  count          = var.subnetting / 2 
  subnet_id      = aws_subnet.main[count.index * 2].id
  route_table_id = aws_route_table.main[0].id
}

resource "aws_route_table_association" "main_private" {
  count          = var.nat_gateway ? var.subnetting / 2 : 0
  subnet_id      = aws_subnet.main[count.index * 2 + 1].id
  route_table_id = aws_route_table.main[1].id
}
