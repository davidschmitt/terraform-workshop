#
# Wrap up our first example by using the VPC module to create our first VPC
# Notice that the region is implied by the aws provider we pass
#
echo '

  module vpc_1 {
    source      = "./vpc"
    tags        = var.tags
    cidr_block  = var.cidr_block_1
    providers   = {
      aws = aws.aws_1
    }
  }

' >modules.tf
