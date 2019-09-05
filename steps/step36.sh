#
# Peering requires resources in two differnt VPCs.  Declare a provider for each
# (these will be passed from the root module)
#
echo '

  provider aws {
    alias = "requester"
  }

  provider aws {
    alias = "accepter"
  }

' >peering/providers.tf
