provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
 
# VPC
resource "aws_vpc" "vpcUSWTA" {
  cidr_block = var.vpc_cidr
 
  tags = {
    Name = "vpcUSWTA"
  }
}
 
# Public subnet 1
resource "aws_subnet" "subPublic1" {
  vpc_id = aws_vpc.vpcUSWTA.id
  cidr_block = var.sub_public1_cidr
  availability_zone = var.aws_az1
 
  tags = {
    Name = "subPublic - USWTA - 1"
  }
}
 
# Public subnet 2
resource "aws_subnet" "subPublic2" {
  vpc_id = aws_vpc.vpcUSWTA.id
  cidr_block = var.sub_public2_cidr
  availability_zone = var.aws_az2
 
  tags = {
    Name = "subPublic - USWTA - 2"
  }
}
 
# Private subnet 1
resource "aws_subnet" "subPrivate1" {
  vpc_id = aws_vpc.vpcUSWTA.id
  cidr_block = var.sub_private1_cidr
  availability_zone = var.aws_az1
 
  tags = {
    Name = "subPrivate - USWTA - 1"
  }
}
 
# Private subnet 2
resource "aws_subnet" "subPrivate2" {
  vpc_id = aws_vpc.vpcUSWTA.id
  cidr_block = var.sub_private2_cidr
  availability_zone = var.aws_az2
 
  tags = {
    Name = "subPrivate - USWTA - 2"
  }
}
 
# Internet gateway
resource "aws_internet_gateway" "igwUSWTA" {
  vpc_id = aws_vpc.vpcUSWTA.id
 
  tags = {
    Name = "igwInternetGateway - USWTA"
  }
}
 
# Security group for bastion host
resource "aws_security_group" "sgUSWTABastion" {
  name = "sgUSWTA - Bastion"
  description = "Allow access on port 22 from restricted IP"
  vpc_id = aws_vpc.vpcUSWTA.id
 
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.ip_address]
  }
 
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "Allow access on port 22 from my IP"
  }
}
 
# Security group for application load balancer
resource "aws_security_group" "sgUSWTAALB" {
  name = "sgUSWTA - ALB"
  description = "Allow access on port 80 from everywhere"
  vpc_id = aws_vpc.vpcUSWTA.id
 
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "Allow HTTP access from everywhere"
  }
}
 
# Security group for application hosts
resource "aws_security_group" "sgUSWTAApplication" {
  name = "sgUSWTA - Application"
  description = "Allow access on ports 22 and 80"
  vpc_id = aws_vpc.vpcUSWTA.id
 
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.sub_public1_cidr]
  }
 
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.sgUSWTAALB.id]
  }
 
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "Allow access on ports 22 and 80"
  }
}

 
# ec2 instance - bastion host
resource "aws_instance" "ec2USWTABastion" {
  ami = var.bastion_ami_id
  instance_type = var.instance_type
  key_name = var.keypair-name
  vpc_security_group_ids = [aws_security_group.sgUSWTABastion.id]
  subnet_id = aws_subnet.subPublic1.id
  associate_public_ip_address = true
 
  root_block_device {
    delete_on_termination = true
  }
 
  tags = {
    Name = "ec2USWTA - Bastion"
  }
}
 
# ec2 instance - app host 1
resource "aws_instance" "ec2USWTAApplication1" {
  ami = var.nginx_ami_id
  instance_type = var.instance_type
  key_name = var.keypair-name
  vpc_security_group_ids = [aws_security_group.sgUSWTAApplication.id]
  subnet_id = aws_subnet.subPrivate1.id
  associate_public_ip_address = false
 
  root_block_device {
    delete_on_termination = true
  }
 
  tags = {
    Name = "ec2USWTA - Application - 1"
  }
}
 
# ec2 instance - app host 2
resource "aws_instance" "ec2USWTAApplication2" {
  ami = var.nginx_ami_id
  instance_type = var.instance_type
  key_name = var.keypair-name
  vpc_security_group_ids = [aws_security_group.sgUSWTAApplication.id]
  subnet_id = aws_subnet.subPrivate2.id
  associate_public_ip_address = false
 
  root_block_device {
    delete_on_termination = true
  }
 
  tags = {
    Name = "ec2USWTA - Application - 2"
  }
}
 
# Elastic IP for the NAT gateway
resource "aws_eip" "eipUSWTA" {
  vpc = true
 
  tags = {
    Name = "eipUSWTA"
  }
}
 
# NAT gateway
resource "aws_nat_gateway" "ngwUSWTA" {
  allocation_id = aws_eip.eipUSWTA.id
  subnet_id     = aws_subnet.subPublic1.id
 
  tags = {
    Name = "ngwUSWTA"
  }
}
 
# Add route to Internet to main route table
resource "aws_route" "rtMainRoute" {
  route_table_id = aws_vpc.vpcUSWTA.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ngwUSWTA.id
}
 
# Create public route table
resource "aws_route_table" "rtPublic" {
  vpc_id = aws_vpc.vpcUSWTA.id
 
  tags = {
    Name = "rtPublic - USWTA"
  }
}
 
# Add route to Internet to public route table
resource "aws_route" "rtPublicRoute" {
  route_table_id = aws_route_table.rtPublic.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igwUSWTA.id
}
 
# Associate public route table with public subnet 1
resource "aws_route_table_association" "rtPubAssoc1" {
  subnet_id   = aws_subnet.subPublic1.id
  route_table_id = aws_route_table.rtPublic.id
}
 
# Associate public route table with public subnet 2
resource "aws_route_table_association" "rtPubAssoc2" {
  subnet_id   = aws_subnet.subPublic2.id
  route_table_id = aws_route_table.rtPublic.id
}
 
# Application Load Balancer
resource "aws_lb" "albUSWTA" {
  name               = "albUSWTA"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.subPublic1.id, aws_subnet.subPublic2.id]
  security_groups = [aws_security_group.sgUSWTAALB.id]
 
  tags = {
    Name = "Application Load Balancer for USWTA"
  }
}
 
# Target group
resource "aws_lb_target_group" "tgUSWTA" {
  name = "tgUSWTA"
  port = "80"
  protocol = "HTTP"
  vpc_id = aws_vpc.vpcUSWTA.id
 
  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/index.html"
    port = 80
    matcher = "200"
    interval            = 30
  }
}
 
# Listener
resource "aws_lb_listener" "lisUSWTA" {
  load_balancer_arn = aws_lb.albUSWTA.arn
  port = "80"
  protocol = "HTTP"
 
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tgUSWTA.arn
  }
}
 
# Add instance 1 to target group
resource "aws_lb_target_group_attachment" "tgaUSWTA1" {
  target_group_arn = aws_lb_target_group.tgUSWTA.arn
  target_id        = aws_instance.ec2USWTAApplication1.id
  port             = "80"
}
 
# Add instance 2 to target group
resource "aws_lb_target_group_attachment" "tgaUSWTA2" {
  target_group_arn = aws_lb_target_group.tgUSWTA.arn
  target_id        = aws_instance.ec2USWTAApplication2.id
  port             = "80"
}