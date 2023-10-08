terraform {
  source = "tfr:///terraform-aws-modules/alb/aws?version=6.0.0"
}

dependencies {
  paths = ["../sg", "../aws_data"]
}

dependency "sg" {
  config_path = "../sg"
  mock_outputs = {
    wrapper = {
      "alb-sg" = {
        security_group_id = "sg-0ca330671e074a05a"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}


dependency "aws_data" {
  config_path = "../aws_data"
  mock_outputs = {
    vpc_id                = "vpc-id"
    r_private_subnets_ids = ["subnet-10.0.1.0", "subnet-10.0.2.0"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}


locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # # Extract out common variables for reuse
  env       = local.environment_vars.locals.environment
  game_code = local.environment_vars.locals.game_code
  country   = local.environment_vars.locals.country


  user_data = <<-EOT
  #!/bin/bash
  echo "Hello Terraform!"
  EOT


}

inputs = {
  name               = "${local.env}-${local.game_code}-${local.country}-alb-mongo-internal"
  vpc_id             = dependency.aws_data.outputs.vpc_id
  subnets            = dependency.aws_data.outputs.r_private_subnets_ids
  security_groups    = [dependency.sg.outputs.wrapper["alb-sg"].security_group_id]
  load_balancer_type = "application"
  internal           = true

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
  target_groups = [
    {
      name             = "${local.env}-tg-${local.game_code}-${local.country}-mongo-internal"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    },
  ]


  tags = {
    Terraform = "true"
  }

}
