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
  count = 2

  subnet_id = aws_subnet.web.*.id[count.index]
  route_table_id = aws_route_table.web.id
}

resource "aws_iam_role" "web-cluster" {
  name = "web-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "web-cluster-AmazonEKSCluterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.web-cluster.name
}

resource "aws_iam_role_policy_attachment" "web-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.web-cluster.name
}

resource "aws_security_group" "web-cluster" {
  name = "web-cluster"
  vpc_id = aws_vpc.web.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-cluster"
  }
}

resource "aws_eks_cluster" "web" {
  name = var.eks-cluster-name
  role_arn = aws_iam_role.web-cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.web-cluster.id]
    subnet_ids = aws_subnet.web.*.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.web-cluster-AmazonEKSCluterPolicy,
    aws_iam_role_policy_attachment.web-cluster-AmazonEKSServicePolicy,
  ]
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
