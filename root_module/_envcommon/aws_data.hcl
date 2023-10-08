locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
  game_code = local.environment_vars.locals.game_code
  template_key_name = local.environment_vars.locals.template_key_name
  country   = local.environment_vars.locals.country
  vpc_name = "${local.env}-vpc-${local.game_code}-${local.country}"
  zone_name = "${local.game_code}.internal"
   
}

inputs = {
  #This module uses the default common vars for this env/region
  #In the future we will reference states using dependencies
  vpc_name = local.vpc_name
  zone_name = local.zone_name
  key_name = local.template_key_name
  }