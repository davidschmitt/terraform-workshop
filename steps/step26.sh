#
# Define a route table for the private subnet to use
# with a default route via the NAT instance
#
echo '
  resource aws_route_table private {
    vpc_id  = var.vpc_id
    tags    = merge(var.tags, {
      Name = "workshop-${var.az_name}-private-route-table"
    })
  }
  resource aws_route private {
    destination_cidr_block  = "0.0.0.0/0"
    route_table_id          = aws_route_table.private.id
    instance_id             = aws_instance.nat
  }
' >>az/resources.tf
