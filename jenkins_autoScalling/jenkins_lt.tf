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

variable subnets_1 {
  description = "Subnets"
  default     = ["subnet-024fa825b28369761", "subnet-042044fee3d344b36"]
}

data "aws_ami" "my_latest_jenkins" {
  most_recent = true
  filter {
    name   = "name"
    values = ["packer-jenkins-pipeline-2*"]
  }
  owners = ["511342350956"]
}

resource "aws_efs_file_system" "efsForJenkins" {
  creation_token = "jenkins-ninad"
  tags = {
    Name = "jenkiinsNinad"
  }
}

resource "aws_efs_mount_target" "alpha" {
  file_system_id = aws_efs_file_system.efsForJenkins.id
  subnet_id      = var.subnets_1[count.index]
  count          = length(var.subnets_1)
} 

data "template_file" "jenkins_setup" {
  template = file("install.sh")
  vars = {
    EFS_ID = "${aws_efs_file_system.efsForJenkins.id}"
  }
}

resource "aws_launch_template" "ninad-jenkins-lt" {
  name = "ninad-jenkins-lt"
  image_id        = data.aws_ami.my_latest_jenkins.id
  instance_type   = "t2.micro"
  key_name        = "ninad-one"
  vpc_security_group_ids  = ["sg-01743b9a9a912fd2c"]
  tags = {
    Name        = "ninad-tf-jenkins"
    createdWith = "terraform"
  }
  instance_initiated_shutdown_behavior = "terminate"
  user_data = base64encode(data.template_file.jenkins_setup.rendered)
}

resource "aws_autoscaling_group" "autoscalling_one" {
  name = "jenkins_autoscalling_ninad"
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  vpc_zone_identifier =   var.subnets_1
  launch_template {
    id      = aws_launch_template.ninad-jenkins-lt.id
    version = "$Latest"
  }
}
resource "aws_lb" "jenkins-lb" {
  name               = "ninad-jenkins-lb-2"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnets_1
  security_groups    = ["sg-0afac1270f2806687"]
  tags = {
    created_With = "terraform"
  }
}

resource "aws_lb_target_group" "jenkins-target-1" {
  name     = "jenkins-target-ninad-1"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "vpc-0daf4cf034673fe93"

}

resource "aws_lb_listener" "jenkins-listener" {
  load_balancer_arn = aws_lb.jenkins-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins-target-1.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_jenkins" {
  autoscaling_group_name = aws_autoscaling_group.autoscalling_one.id
  elb                    = aws_lb.jenkins-lb.id
}

output "lb_dns" {
  value = aws_lb.jenkins-lb.dns_name
}

output "lt-name" {
  value = aws_launch_template.ninad-jenkins-lt.id
}

