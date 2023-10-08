terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws//wrappers?version=4.2.1"
}

dependencies {
  paths = ["../sg", "../aws_data"]
}

dependency "sg" {
  config_path = "../sg"
  mock_outputs = {
    wrapper = {
      "ec2-sg" = {
        security_group_id = "sg-0ca330671e074a05a"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}


dependency "aws_data" {
  config_path = "../aws_data"
  mock_outputs = {
    r_private_subnets_ids = ["subnet-10.0.1.0", "subnet-10.0.2.0"]
    amazon_linux2         = "ami-0111111"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}


locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # # Extract out common variables for reuse
  env               = local.environment_vars.locals.environment
  game_code         = local.environment_vars.locals.game_code
  country           = local.environment_vars.locals.country
  template_key_name = local.environment_vars.locals.template_key_name
  instance_type     = "t3.micro"
  data_vol_size     = "10"

  user_data = <<-EOT
  #!/bin/bash
  echo "Hello Terraform!"
  EOT

}


inputs = {

  items = {
    "mongodb-pri" = {
      name                   = "${local.env}-${local.game_code}-${local.country}-mongodb-pri"
      ami                    = dependency.aws_data.outputs.amazon_linux2
      instance_type          = local.instance_type
      subnet_id              = dependency.aws_data.outputs.r_private_subnets_ids[0]
      vpc_security_group_ids = [dependency.sg.outputs.wrapper["ec2-sg"].security_group_id]
      key_name               = local.template_key_name
      enable_volume_tags     = true
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 30
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = local.data_vol_size
          encrypted   = true
        }
      ]
    }
    "mongodb-sec" = {
      name                        = "${local.env}-${local.game_code}-${local.country}-mongodb-sec"
      ami                         = dependency.aws_data.outputs.amazon_linux2
      instance_type               = local.instance_type
      subnet_id                   = dependency.aws_data.outputs.r_private_subnets_ids[1]
      vpc_security_group_ids      = [dependency.sg.outputs.wrapper["ec2-sg"].security_group_id]
      key_name                    = local.template_key_name
      create_iam_instance_profile = true
      iam_role_description        = "IAM role for MongoDB EC2 instance"
      iam_role_policies = {
        AmazonEC2ReadOnlyAccess     = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }

      enable_volume_tags = true
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 30
        }
      ]
      ebs_block_device = [
        {
          device_name = "/dev/sdf"
          volume_type = "gp3"
          volume_size = local.data_vol_size
          encrypted   = true
        }
      ]
    }
    "mongodb-arb" = {
      name                        = "${local.env}-${local.game_code}-${local.country}-mongodb-arb"
      ami                         = dependency.aws_data.outputs.amazon_linux2
      instance_type               = local.instance_type
      subnet_id                   = dependency.aws_data.outputs.r_private_subnets_ids[1]
      vpc_security_group_ids      = [dependency.sg.outputs.wrapper["ec2-sg"].security_group_id]
      key_name                    = local.template_key_name
      create_iam_instance_profile = true
      iam_role_description        = "IAM role for MongoDB EC2 instance"
      iam_role_policies = {
        AmazonEC2ReadOnlyAccess     = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }

      enable_volume_tags = true
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 30
        }
      ]
    }

    "bastion-mongo" = {
      name                        = "${local.env}-${local.game_code}-${local.country}-mongodb-bastion"
      ami                         = dependency.aws_data.outputs.amazon_linux2
      instance_type               = "t3.micro"
      subnet_id                   = dependency.aws_data.outputs.r_public_subnets_ids[1]
      vpc_security_group_ids      = [dependency.sg.outputs.wrapper["ec2-sg"].security_group_id]
      key_name                    = local.template_key_name
      create_iam_instance_profile = true
      associate_public_ip_address = true
      iam_role_description        = "IAM role for bastion EC2 instance"
      iam_role_policies = {
        AmazonEC2ReadOnlyAccess     = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }

      enable_volume_tags = true
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          volume_size = 30
        }
      ]
    }
  }

  tags = {
    Terraform = "true"
  }
}
