#
# Once the keypair is created we need to register it with AWS so we can use it 
# during EC2 creation.  We use unique key names in case 
# aws_1 and aws_2 are in the same region.
#
echo '

  resource aws_key_pair keypair1 {
    provider = aws.aws_1
    key_name   = "workshop-keypair-1"
    public_key = tls_private_key.keypair.public_key_openssh
  }

  resource aws_key_pair keypair2 {
    provider = aws.aws_2
    key_name   = "workshop-keypair-2"
    public_key = tls_private_key.keypair.public_key_openssh
  }

' >>resources.tf
