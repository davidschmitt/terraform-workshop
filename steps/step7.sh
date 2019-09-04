#
# Define the provider in our root module that we will use for our first VPC
#
echo '
  provider aws {
    region  = var.region_1
    alias   = "aws_1"
  }
' >providers.tf
