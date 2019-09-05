#
# This code generates a key pair so we can test connectivity to the servers
# It writes out the private key so we can use it to SSH into the bastion host
#
echo '

  resource tls_private_key keypair {
    algorithm = "RSA"
    rsa_bits  = 4096
  }

  resource local_file private_key {
    sensitive_content = tls_private_key.keypair.private_key_pem
    filename = "${path.module}/private.pem"
  }

' >resources.tf
