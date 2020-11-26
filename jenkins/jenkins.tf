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

data "aws_ami" "my_latest_1" {
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

  user_data = data.template_file.jenkins_setup.rendered

}

output "jenkins-ip" {
  value = aws_instance.ninad-tf-three.public_dns
}

output "jenkins-ip-2" {
  value = aws_instance.ninad-tf-three.public_ip
}