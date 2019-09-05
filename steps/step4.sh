#
# Now we define the VPC resource in the child module based on the 
# variables passed to it.
# Notice how we merge the general tags with the Name tag
#
echo '

  resource aws_vpc vpc {
    cidr_block  = var.cidr_block
    tags        = merge(var.tags, {
      Name = "workshop-vpc"
    })
  }

' >vpc/resources.tf
