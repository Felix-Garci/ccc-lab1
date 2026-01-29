#VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.vpc_cidr_block
  availability_zone       = var.availability_zone
  
  map_public_ip_on_launch = true 

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Permitir trafico HTTP y ICMP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP from Internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "ICMP Ping"
    from_port        = -1  
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH from Internet"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" 
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}



# EC2
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  key_name      = "vockey" 

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  
  iam_instance_profile        = "LabInstanceProfile"
  
  monitoring                  = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3" 
  }

  user_data = file("${path.module}/../scripts/bootstrap-nginx.sh")


  tags = {
    Name = "team-name-ec2"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "team-name-cpu-high-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2" 
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60" 
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Alarma cuando CPU > 70%"
  
  dimensions = {
    InstanceId = aws_instance.web_server.id
  }
  
}


# Peering 
resource "aws_vpc_peering_connection" "peer" {
  count         = var.peer_vpc_id != "" ? 1 : 0
  
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = var.peer_vpc_id
  peer_owner_id = var.peer_owner_id
  
  auto_accept   = false 

  tags = {
    Name = "team-name-peering"
  }
}

resource "aws_route" "peer_route" {
  count                     = var.peer_vpc_id != "" ? 1 : 0
  
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = var.peer_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer[0].id
}
