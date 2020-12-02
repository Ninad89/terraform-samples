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
resource "aws_instance" "ninad-tf-one" {
  ami           = data.aws_ami.my_latest.id
  instance_type = "t2.micro"
  key_name      = "ninad-one"

  tags = {
    Name        = "ninad-tf-1"
    createdWith = "terraform"
  }
  count = 3
}
