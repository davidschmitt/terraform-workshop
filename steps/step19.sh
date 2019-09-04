#
# Define local values to calculate an az_name offset.
# That offset will be used to automatically calculate
# subnet CIDR blocks.
#
echo '
  locals {
    region = data.aws_region.current.name
    azs = [
      "${local.region}a",
      "${local.region}b",
      "${local.region}c",
      "${local.region}d",
      "${local.region}e",
      "${local.region}f",
      "${local.region}g",
      "${local.region}h"
    ]
    offset = index(local.azs, var.az_name)
    cidr_block = data.aws_vpc.current.cidr_block
  }
' >az/locals.tf
