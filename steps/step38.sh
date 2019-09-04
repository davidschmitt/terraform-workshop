#
# Add routes between the peered VPCs
# Notice how we use the count mechanism to create more than one route at a time
#
echo '
  resource aws_route vpc_routes {
    count = length(var.requester_route_table_ids)
    provider = aws.requester
    route_table_id = var.requester_route_table_ids[count.index]
    destination_cidr_block = data.aws_vpc.accepter.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
  }
  resource aws_route peer_routes {
    count = length(var.accepter_route_table_ids)
    provider = aws.accepter
    route_table_id = var.accepter_route_table_ids[count.index]
    destination_cidr_block = data.aws_vpc.requester.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
  }
' >>peering/resources.tf
