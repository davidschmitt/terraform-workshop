#
# Add a public subnet resource.  We use the offset to calculate CIDR blocks
# that we know won't overlap.
#
echo '

  resource aws_subnet public {
    availability_zone = var.az_name
    cidr_block        = cidrsubnet(local.cidr_block, 4, local.offset * 2)
    vpc_id            = var.vpc_id
    tags              = merge(var.tags, {
      Name = "workshop-${var.az_name}-public-subnet"
    })
  }

  resource aws_route_table_association public {
    subnet_id       = aws_subnet.public.id
    route_table_id  = var.public_route_table_id
  }

' >>az/resources.tf
