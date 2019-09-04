#
# We create a terraform.tfvars file in our root module so that we won't
# have to retype the variable values every time we run terraform.
#
echo '
  cidr_block_1  = "10.1.0.0/16"
  region_1      = "us-east-1"
  tags          = {
    Project = "Terraform Workshop Demo"
    Owner   = "me@example.com"
  }
' >terraform.tfvars
