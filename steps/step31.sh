#
# Add the second VPC values to the terraform.tfvars file
#
echo '
  cidr_block_2  = "10.2.0.0/16"
  region_2      = "us-east-1"
' >>terraform.tfvars
