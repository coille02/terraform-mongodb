module "wrapper" {
  source = "github.com/terraform-aws-modules/terraform-aws-security-group.git"

  for_each = var.items

  ingress_cidr_blocks      = try(each.value.ingress_cidr_blocks, var.defaults.ingress_cidr_blocks, [])
  ingress_rules            = try(each.value.ingress_rules, var.defaults.ingress_rules, [])
  vpc_id                   = try(each.value.vpc_id, var.defaults.vpc_id, null)
  name                     = try(each.value.name, var.defaults.name, null)
  ingress_with_cidr_blocks = try(each.value.ingress_with_cidr_blocks, var.defaults.ingress_with_cidr_blocks, [])
  egress_with_cidr_blocks  = try(each.value.egress_with_cidr_blocks, var.defaults.egress_with_cidr_blocks, [])
  tags                     = try(each.value.tags, var.defaults.tags, {})

}
