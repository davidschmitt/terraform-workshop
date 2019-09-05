#
# Since we have peered the VPCs we can access this internal server
# via the bastion in the other VPC
#
echo '

  resource aws_instance server {
    provider                    = aws.aws_2
    instance_type               = "t2.nano"
    key_name                    = aws_key_pair.keypair2.key_name
    ami                         = module.az_2.nat_ami_id
    subnet_id                   = module.az_2.private_subnet_id
    vpc_security_group_ids      = [ module.vpc_2.default_security_group_id ]
    tags = merge(var.tags, { 
      Name = "workshop-server"
    })
  }

' >>resources.tf
