terraform {
  source = "../../../modules/sg"


}

dependencies {
  paths = ["../aws_data"]
}

dependency "aws_data" {
  config_path = "../aws_data"
  mock_outputs = {
    vpc_id         = "vpc-id"
    vpc_cidr_block = "10.0.0.0/21"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  env       = local.environment_vars.locals.environment
  game_code = local.environment_vars.locals.game_code
  country   = local.environment_vars.locals.country

  m_cidr          = "10.5.190.0/23"
  office_ip_cidr  = "111.91.143.21/32"
  jenkins_ip_cidr = "10.5.106.74/32"
  Bastion_ip_cidr = "10.6.106.83/32"

}



inputs = {
  items = {
    alb-sg = {

      ingress_cidr_blocks = [dependency.aws_data.outputs.vpc_cidr_block]


      # List of ingress rules to create by name
      # type: list(string)
      ingress_rules = ["https-443-tcp", "http-80-tcp"]

      # Name of security group
      # type: string
      name = "${local.env}-sg-${local.game_code}-${local.country}-alb-mongo"

      # ID of the VPC where to create security group
      # type: string
      vpc_id = dependency.aws_data.outputs.vpc_id

      description = "Managed my Terraform"
      tags = {
        Name = "${local.env}-sg-${local.game_code}-${local.country}-alb-mongo"
      }
    }
    ec2-sg = {
      #   for_each = local.rules
      ingress_cidr_blocks = [dependency.aws_data.outputs.vpc_cidr_block]


      # List of ingress rules to create by name
      # type: list(string)
      ingress_rules = ["https-443-tcp", "http-80-tcp"]

      # Name of security group
      # type: string
      name = "${local.env}-sg-${local.game_code}-${local.country}-mongo"

      # ID of the VPC where to create security group
      # type: string
      vpc_id = dependency.aws_data.outputs.vpc_id

      ingress_with_cidr_blocks = [
        {
          rule        = "mongodb-27017-tcp"
          cidr_blocks = local.office_ip_cidr
          description = "# LG Office IP"
        },
        {
          rule        = "mongodb-27017-tcp"
          cidr_blocks = "10.3.4.203/32"
          description = "# vpc-allnet-core bi-tool (kate)"
        },
        {
          rule        = "mongodb-27017-tcp"
          cidr_blocks = "10.3.4.241/32"
          description = "# vpc-allnet-core bi-analytics-jenkins"
        },
        {
          rule        = "mongodb-27017-tcp"
          cidr_blocks = "10.3.4.85/32"
          description = "# LG Infra Jenkins"
        },
        {
          rule        = "mongodb-27017-tcp"
          cidr_blocks = "172.30.0.0/16"
          description = "# vpc-allnet platform api range (private)"
        },
        {
          rule        = "mongodb-27017-tcp"
          cidr_blocks = local.m_cidr
          description = "# m-vpc"
        },
        {
          rule        = "mongodb-27017-tcp"
          cidr_blocks = dependency.aws_data.outputs.vpc_cidr_block
          description = "# r-vpc"
        },
        {
          rule        = "zabbix-agent"
          cidr_blocks = dependency.aws_data.outputs.vpc_cidr_block
          description = "# r-vpc"
        },
        {
          rule        = "ssh-tcp"
          cidr_blocks = local.jenkins_ip_cidr
          description = "# Deploy Server"
        },
        {
          rule        = "ssh-tcp"
          cidr_blocks = local.office_ip_cidr
          description = "# LG Office IP"
        },
        {
          rule        = "ssh-tcp"
          cidr_blocks = local.Bastion_ip_cidr
          description = "# Bastion Server IP"
        },
      ]

      egress_with_cidr_blocks = [
        {
          rule        = "all-all"
          cidr_blocks = "0.0.0.0/0"
        },
      ]

      description = "Managed my Terraform"
      tags = {
        Name = "${local.env}-sg-${local.game_code}-${local.country}-mongo"
      }
    }

  }
}
