data "aws_vpc" "r-vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "r_private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.r-vpc.id]
  }

  filter {
    name   = "tag:subnet"
    values = ["r-sn-private"]
  }
}

data "aws_subnets" "r_public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.r-vpc.id]
  }

  filter {
    name   = "tag:subnet"
    values = ["r-sn-public"]
  }
}


data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["347265212188"] # Amazon

  filter {
    name   = "name"
    values = ["amzn2-5x-ami-hvm-20220614-clean"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}


data "aws_ami" "amzn2_mongo_api_ami" {
  most_recent = true
  owners      = ["528584883683"] # Amazon

  filter {
    name   = "name"
    values = ["amzn2-5x-ami-hvm-*-packer-mongoapi"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}
data "aws_route53_zone" "internal_zone" {
  name         = var.zone_name
  private_zone = true
}

data "aws_key_pair" "ec2_key" {
  key_name           = var.template_key_name

}
# output.tf 

# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.r-vpc.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR BLOCK"
  value       = data.aws_vpc.r-vpc.cidr_block
}

output "r_private_subnets_ids" {
  description  = "Private Subnet ID 리스트"
  value        = sort(data.aws_subnets.r_private_subnets.ids)
}

output "r_public_subnets_ids" {
  description  = "Public Subnet ID 리스트"
  value        = sort(data.aws_subnets.r_public_subnets.ids)
}

output "amazon_linux2" {
  description  = "amzn2 Clean-Up Image"
  value        = data.aws_ami.amazon_linux2.id
}

output "amzn2_mongo_api_ami" {
  description  = "amzn2 mongo api ami Clean-Up Image"
  value        = data.aws_ami.amzn2_mongo_api_ami.id
}

output "internal_zone_id" {
  description = "Internal Zone ID"
  value       = data.aws_route53_zone.internal_zone.id
}

output "internal_zone_name" {
  description = "Internal Zone name"
  value       = data.aws_route53_zone.internal_zone.name
}

output "ec2_key_id" {
  description = "EC2 Key id"
  value       = data.aws_key_pair.ec2_key.id
}
# Variables 

variable "vpc_name" {}
variable "zone_name" {}
variable "template_key_name" {}
