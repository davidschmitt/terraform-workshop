#
# Use provider data sources to find extra info for peering.
# Notice that we use the two separate AWS providers - one for each VPC
#
echo '

  data aws_vpc requester {
    provider = aws.requester
    id = var.requester_id
  }

  data aws_vpc accepter {
    provider = aws.accepter
    id = var.accepter_id
  }

  data aws_region accepter {
    provider = aws.accepter
  }

  data aws_caller_identity accepter {
    provider = aws.accepter
  }

' >peering/data.tf
