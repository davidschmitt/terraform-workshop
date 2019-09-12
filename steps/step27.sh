#
# Define the private subnet
# The "depends_on" means we won't accidentally try to spin up EC2 instances
# in the private subnet before the NAT comes up.
#
echo '

  resource aws_subnet private {
    vpc_id            = var.vpc_id
    availability_zone = var.az_name
    cidr_block        = cidrsubnet(local.cidr_block, 4, local.offset * 2 + 1)
    depends_on        = [ aws_instance.nat ]
    tags              = merge(var.tags, {
      Name = "workshop-${var.az_name}-private-subnet"
    })
  }

  resource aws_route_table_association private_nat_rt_assoc {
    subnet_id       = aws_subnet.private.id
    route_table_id  = aws_route_table.private.id
  }

' >>az/resources.tf
