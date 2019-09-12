#
# Add the second provider alias to the root module
#
echo '

  provider aws {
    region  = var.region_2
    alias   = "aws_2"
  }

' >>providers.tf
