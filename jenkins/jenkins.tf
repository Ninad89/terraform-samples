terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile    = "default"
  region     = "eu-west-2"
  access_key = "AKIAXODTBCJWGPYZEATM"
  secret_key = "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"
}

data "aws_ami" "my_latest_1" {
  most_recent = true
  filter {
    name   = "name"
    values = ["test-image-ninad*"]
  }
  owners = ["511342350956"]
}

resource "aws_instance" "ninad-tf-three" {
  ami             = data.aws_ami.my_latest_1.id
  instance_type   = "t2.micro"
  key_name        = "ninad-one"
  subnet_id       = "subnet-024fa825b28369761"
  security_groups = ["sg-01743b9a9a912fd2c"]
  tags = {
    Name        = "ninad-tf-jenkins"
    createdWith = "terraform"
  }
  user_data = file("install.sh")
}

output "jenkins-ip" {
  value = aws_instance.ninad-tf-three.public_dns
}

output "jenkins-ip-2" {
  value = aws_instance.ninad-tf-three.public_ip
}