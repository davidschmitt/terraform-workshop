#
# We want to peer our two VPCs.  Here we create a new child module for peering and describe its variables
#
mkdir -p ./peering && echo '

  variable requester_id {
    type = string
    description = "The id of the requester vpc"
  }

  variable requester_route_table_ids {
    type = list(string)
    description = "A list of route table ids to which the accepter CIDR block should be added"
  }

  variable accepter_id {
    type = string
    description = "The id of the accepter vpc"
  }

  variable accepter_route_table_ids {
    type = list(string)
    description = "A list of peer route table ids to which the requester CIDR block should be added"
  }

  variable tags {
    type = map(string)
    description = "General tags to apply to all resources"
  }

' >peering/vars.tf
