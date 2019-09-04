#
# Add the second VPC and second AZ to the root module.
# Notice how easy it is since child modules are reusable.
#
echo '
  module vpc_2 {
    source      = "./vpc"
    tags        = var.tags
    cidr_block  = var.cidr_block_2
    providers   = {
      aws = aws.aws_2
    }
  }
  module az_2 {
    source                    = "./az"
    tags                      = var.tags
    az_name                   = "${var.region_2}b"
    vpc_id                    = module.vpc_2.vpc_id
    public_route_table_id     = module.vpc_2.public_route_table_id
    default_security_group_id = module.vpc_2.default_security_group_id
    providers                 = {
      aws = aws.aws_2
    }
  }
' >>modules.tf
