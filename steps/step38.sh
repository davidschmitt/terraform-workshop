#
# Now we can declare the actual peering
#
echo '
  resource aws_vpc_peering_connection requester {
    provider = aws.requester
    vpc_id = var.requester_id
    peer_vpc_id = var.accepter_id
    peer_region = data.aws_region.accepter.name
    peer_owner_id = data.aws_caller_identity.accepter.account_id
    auto_accept = false
    tags = merge(var.tags, { 
      Name = "workshop-peering"
    })
  }
  resource aws_vpc_peering_connection_accepter accepter {
    provider = aws.accepter
    vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
    auto_accept = true
    tags = merge(var.tags, { 
      Name = "workshop-peering"
    })
  }
' >peering/resources.tf
