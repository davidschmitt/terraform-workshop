#
# We want to attach a key pair so that you can test connectivity to the bastion host and internal server
#
echo '
  variable key_pair {
    type = string
    description = "The name of a key pair to attach to a bastion host and internal server for testing purposes"
  }
' >>vars.tf
