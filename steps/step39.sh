#
# In the root module, use the peering sub-module to actually establish peering
#
echo '
  module peering_1_2 {
    source                    = "./az"
    tags                      = var.tags
    requester_id              = module.vpc_1.vpc_id
    accepter_id               = module.vpc_2.vpc_id
    requester_route_table_ids = [ 
      module.vpc_1.public_route_table_id,
      module.az_1.private_route_table_id
    ]
    accepter_route_table_ids  = [
      module.vpc_2.public_route_table_id,
      module.az_2.private_route_table_id
    ]
    providers                 = {
      aws.requester = aws.aws_1
      aws.accepter = aws.aws_2
    }
  }
' >>modules.tf
