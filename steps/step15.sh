#
# We will need some of the VPC resource information to create subnets later.
# Define the outputs so they will be available when we need them
#
echo '

  output vpc_id {
    value = aws_vpc.vpc.id
  }

  output public_route_table_id {
    value = aws_route_table.public.id
  }

  output default_security_group_id {
    value = aws_security_group.default.id
  }

' >vpc/outputs.tf
