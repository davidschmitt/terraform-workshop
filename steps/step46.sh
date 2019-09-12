#
# The EC2 resources here are not re-usable, so we just put them in the root module
# We could use count here if we wanted a separate bastion for each VPC
#
echo '

  resource aws_instance bastion {
    provider                    = aws.aws_1
    associate_public_ip_address = true
    instance_type               = "t2.nano"
    key_name                    = aws_key_pair.keypair1.key_name
    ami                         = module.az_1.nat_ami_id
    subnet_id                   = module.az_1.public_subnet_id
    vpc_security_group_ids      = [ module.vpc_1.default_security_group_id ]
    tags = merge(var.tags, { 
      Name = "workshop-bastion"
    })
  }

' >>resources.tf
