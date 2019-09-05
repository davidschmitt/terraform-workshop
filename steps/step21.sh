#
# Add the az child module to our root module
#
echo '

  module az_1 {
    source                    = "./az"
    tags                      = var.tags
    az_name                   = "${var.region_1}a"
    vpc_id                    = module.vpc_1.vpc_id
    public_route_table_id     = module.vpc_1.public_route_table_id
    default_security_group_id = module.vpc_1.default_security_group_id
    providers                 = {
      aws = aws.aws_1
    }
  }

' >>modules.tf
