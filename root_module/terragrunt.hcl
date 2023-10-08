#root_module/terragrunt.hcl

locals {
  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # # Extract out common variables for reuse
  env               = local.environment_vars.locals.environment
  game_code         = local.environment_vars.locals.game_code
  country           = local.environment_vars.locals.country
  aws_region        = local.region_vars.locals.aws_region
  template_key_name = local.environment_vars.locals.template_key_name
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
    #if_exists = "skip"
  }

  config = {
    bucket         = "terragrunt-coille-001"
    encrypt        = true
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terragrunt-lock-${replace(path_relative_to_include(), "/", "-")}"
  }
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  # Only these AWS Account IDs may be operated on by this template
  default_tags {
      tags = {
      Create-by = "Terraform"
      }
    }
}
EOF
}

inputs = merge(
  local.region_vars.locals,
  local.environment_vars.locals,
)