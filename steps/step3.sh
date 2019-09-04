#
# Since we plan to have more than one VPC we want a reusable VPC module.
# Here we create the VPC module directory and define the variables it needs
#
mkdir -p ./vpc && echo '
  variable tags {
    type        = map(string)
    description = "General tags to apply on all resources"
  }
  variable cidr_block {
    type        = string
    description = "The CIDR block of the VPC"
  }
' >vpc/vars.tf
