#
# We will ask the user to provide a key_pair (since creating one is outside the scope of this workshop)
#
echo '
  variable key_pair {
    type = string
    description = "The name of a key pair to attach to a bastion host and internal server for testing purposes"
  }
' >>vars.tf
