#
# Now we'll create an availability zone child module and define the variables it will need
#
mkdir -p az && echo '

  variable tags {
    description = "General tags to assign to all resources"
    type = map(string)
  }

  variable az_name {
    description = "Availability Zone Name"
    type = string
  }

  variable vpc_id {
    description = "VPC ID"
    type = string
  }

  variable public_route_table_id {
    description = "Public route table ID"
    type = string
  }

  variable default_security_group_id {
    description = "Default Security Group ID"
    type = string
  }

' >az/vars.tf
