#
# Define extra variables in the root module for our second VPC
#
echo '
  variable region_2 {
    type        = string
    description = "The AWS region of the second VPC"
  }
  variable cidr_block_2 {
    type        = string
    description = "The CIDR block of the second VPC"
  }
' >>vars.tf
