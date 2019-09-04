#
# Append gateway and routing resources so we can talk to the Internet
#
echo '
  resource aws_internet_gateway igw {
    vpc_id = aws_vpc.vpc.id
    tags = merge(var.tags, {
      Name = "workshop-internet-gateway"
    })
  }
  resource aws_route_table public {
    vpc_id = aws_vpc.vpc.id
    tags = merge(var.tags, {
      Name = "workshop-public-route-table"
    })
  }
  resource aws_route default {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
' >>vpc/resources.tf
