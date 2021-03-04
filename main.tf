module "vpc" {
  source        = "./modules/vpc"
  name_prefix   = local.name_prefix
  default_tags  = local.default_tags
}
