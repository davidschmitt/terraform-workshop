#
# Now we define some variables in our root level module.
# As you might expect, we will be passing the cidr_block_1 value
# into the VPC child module.
#
echo '
  variable tags {
    type        = map(string)
    description = "Tags we want to apply to all of our resources"
  }
  variable region_1 {
    type        = string
    description = "The AWS region of the first VPC"
  }
  variable cidr_block_1 {
    type        = string
    description = "The CIDR block of the first VPC"
  }
' >vars.tf
