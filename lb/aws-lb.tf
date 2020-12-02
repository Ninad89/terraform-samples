terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

variable AWS_ACCESS_KEY {
  type = string
}

variable AWS_SECRET_KEY {
  type = string
}

provider "aws" {
  profile    = "default"
  region     = "eu-west-2"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}
data "aws_ami" "my_latest" {
  most_recent = true
  filter {
    name   = "name"
    values = ["test-image-ninad*"]
  }
  owners = ["511342350956"]
}

variable subnets {
  description= "Subnets"
  default = ["subnet-024fa825b28369761","subnet-042044fee3d344b36","subnet-024fa825b28369761"]
}

resource "aws_instance" "ninad-tf-two" {
  ami             = data.aws_ami.my_latest.id
  instance_type   = "t2.micro"
  key_name        = "ninad-one"
  subnet_id       = var.subnets[count.index]
  security_groups = ["sg-01743b9a9a912fd2c"]
  tags = {
    Name        = "ninad-tf-${count.index}"
    createdWith = "terraform"
  }
  user_data = file("efs.sh")
  count     = length(var.subnets)
}

output "ip" {
  value = {
    for ec2 in aws_instance.ninad-tf-two :
    ec2.id => ec2.public_dns
  }
}

resource "aws_lb_target_group" "test-target-1" {
  name     = "test-target-ninad-1"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "vpc-0daf4cf034673fe93"

}

resource "aws_lb_target_group_attachment" "test-target-attachment" {
  target_group_arn = aws_lb_target_group.test-target-1.arn
  target_id        = aws_instance.ninad-tf-two[count.index].id
  count            = length(var.subnets)
}

resource "aws_lb" "ninad-test-lb" {
  name               = "ninad-test-lb-2"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-024fa825b28369761", "subnet-042044fee3d344b36"]
  security_groups    = ["sg-0afac1270f2806687"]
  tags = {
    created_With = "terraform"
  }
}

resource "aws_lb_listener" "ninad-test-listener" {
  load_balancer_arn = aws_lb.ninad-test-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test-target-1.arn
  }
}

resource "aws_lb_listener" "ninad-test-listener-https" {
  load_balancer_arn = aws_lb.ninad-test-lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:eu-west-2:511342350956:certificate/59c67e82-abd2-4cc8-9d74-d36b72ca8e7b"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test-target-1.arn
  }
}

output "lb_dns" {
  value = aws_lb.ninad-test-lb.dns_name
}