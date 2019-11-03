data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "web" {
  cidr_block = "10.0.0.0/16"

  tags = map(
          "Name", "web",
          "kubernetes.io/cluster/${var.eks-cluster-name}", "shared",
  )
}

resource "aws_subnet" "web" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id = aws_vpc.web.id

  tags = map(
          "Name", "web",
          "kubernetes.io/cluster/${var.eks-cluster-name}}", "shared",
  )
}

resource "aws_internet_gateway" "web" {
  vpc_id = aws_vpc.web.id

  tags = {
    Name = "web"
  }
}

resource "aws_route_table" "web" {
  vpc_id = aws_vpc.web.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web.id
  }
}

resource "aws_route_table_association" "web" {
  count =2

  subnet_id = aws_subnet.web.*.id[count.index]
  route_table_id = aws_route_table.web.id
}


resource "aws_db_instance" "rds" {
  identifier = var.rds_identifier
  allocated_storage = 20
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "11.5"
  instance_class = "db.t2.micro"
  name = var.rds_name
  username = "postgres"
  password = "postgres"
  skip_final_snapshot = "true"
}
