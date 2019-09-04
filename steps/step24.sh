#
# We will need a NAT instance for our private subnet
#
echo '
  resource aws_instance nat {
    ami                         = data.aws_ami.nat_ami.id
    instance_type               = "t2.nano"
    subnet_id                   = aws_subnet.public.id
    associate_public_ip_address = true
    vpc_security_group_ids      = [ var.default_security_group_id ]
    source_dest_check           = false
    tags                        = merge(var.tags, { 
      Name = "workshop-${var.az_name}-nat"
    })
  }
' >>az/resources.tf
