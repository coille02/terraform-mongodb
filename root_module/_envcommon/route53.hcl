terraform {
  source = "tfr:///terraform-aws-modules/route53/aws//modules/records?version=2.10.1"
}

dependencies {
  paths = ["../aws_data", "../ec2", "../alb"]
}

dependency "ec2" {
  config_path = "../ec2"
  mock_outputs = {
    wrapper = {
      "mongodb-pri" = {
        private_ip = "10.10.10.10"
      }
      "mongodb-sec" = {
        private_ip = "10.10.10.11"
      }
      "mongodb-arb" = {
        private_ip = "10.10.10.11"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs = {
    lb_dns_name = "security-group-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "aws_data" {
  config_path = "../aws_data"
  mock_outputs = {
    internal_zone_id = "Z034198238ILLURDA56VW"

  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}


locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  env       = local.environment_vars.locals.environment
  game_code = local.environment_vars.locals.game_code
  country   = local.environment_vars.locals.country
}

inputs = {
  zone_id      = dependency.aws_data.outputs.internal_zone_id
  private_zone = true

  records_jsonencoded = jsonencode([
    {
      name    = "${local.env}-${local.country}-mongodb-pri"
      type    = "A"
      ttl     = 3600
      records = ["${dependency.ec2.outputs.wrapper["mongodb-pri"].private_ip}", ]
    },
    {
      name    = "${local.env}-${local.country}-mongodb-sec"
      type    = "A"
      ttl     = 3600
      records = ["${dependency.ec2.outputs.wrapper["mongodb-sec"].private_ip}", ]
    },
    {
      name    = "${local.env}-${local.country}-mongodb-arb"
      type    = "A"
      ttl     = 3600
      records = ["${dependency.ec2.outputs.wrapper["mongodb-arb"].private_ip}", ]
    },
    {
      name    = "${local.env}-${local.country}-mongodb-api"
      type    = "CNAME"
      ttl     = 3600
      records = ["${dependency.alb.outputs.lb_dns_name}.", ]
    }
  ])
}


