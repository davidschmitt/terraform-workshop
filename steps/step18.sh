#
# In order to avoid extra variables for the user to populate 
# we use the AWS provider data sources to find values for us
#
echo '

  data aws_region current { }

  data aws_vpc current {
    id = var.vpc_id
  }

  data aws_ami nat_ami {
    most_recent = true
    owners = ["amazon"]
    filter {
      name   = "name"
      values = ["amzn-ami-vpc-nat-hvm-*-x86_64-ebs"]
    }
  }

' >az/data.tf
