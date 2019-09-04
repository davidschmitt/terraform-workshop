#
# In order to employ the subnets from the AZs we need to export their ID values from the child module.
# We also need the private route table for VPC peering.
# We export the NAT ami ID to use for a bastion host and internal server later on (even though
# they won't be actual NAT instances)
#
echo '
  output public_subnet_id {
    value = aws_subnet.public.id
  }
  output private_subnet_id {
    value = aws_subnet.private.id
  }
  output private_route_table_id {
    value = aws_route_table.private.id
  }
  output nat_ami_id {
    value = data.aws_ami.nat_ami.id
  }
' >az/outputs.tf
