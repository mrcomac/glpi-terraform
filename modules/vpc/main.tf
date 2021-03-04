data "aws_availability_zones" "available" {}

#main VPC
resource "aws_vpc" "main" {
    cidr_block="10.0.0.0/16"
    instance_tenancy="default"
    enable_dns_hostnames = true
    tags = merge({
              Name = "${var.name_prefix}-vpc"
           }, var.default_tags)
}

#Create Public Subnets for ALB
resource "aws_subnet" "public_subnet" {
  count                   = var.n_public_subnet
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags = merge({
            Name = "${var.name_prefix}-public-subnet-${count.index}"
         }, var.default_tags)

}

#Private subnets don't have internet access
resource "aws_subnet" "private_subnet" {
  count = var.n_private_subnet
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.${count.index+var.n_public_subnet}.0/24"
  tags = merge({
            Name = "${var.name_prefix}-private-subnet-${count.index}"
         },var.default_tags)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
}

#Create Internet GW for public subnets
resource "aws_internet_gateway" "GW-Public" {
  vpc_id  = aws_vpc.main.id
  tags = merge({
        Name = "${var.name_prefix}-Internet Gateway"
      }, var.default_tags)
}

resource "aws_route_table" "RT-Public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.GW-Public.id
  }
  tags = merge({
            Name = "${var.name_prefix}-RT-Public"
         },var.default_tags)

}

#route table for public subnets
resource "aws_route_table_association" "rt-public-association" {
   count          = length(aws_subnet.public_subnet)
   subnet_id      = aws_subnet.public_subnet[count.index].id
   route_table_id =  aws_route_table.RT-Public.id
}
