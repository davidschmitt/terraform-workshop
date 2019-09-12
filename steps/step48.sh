#
# Since Terraform knows the IP addresses of the EC2 instances, let's have it generate a helper script 
# that lets us jump to the internal server via the bastion host.
#
# (Just ignore the SSH syntax ugliness right now)
#
echo '

  resource local_file jump {
    content = join("\n", [
      "#!/bin/bash",
      "OPTS=\"-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null\"",
      "PROXYCMD=\"ProxyCommand=ssh -i private.pem $OPTS -W %h:%p ec2-user@${aws_instance.bastion.public_ip}\"",
      "SERVER=\"ec2-user@${aws_instance.server.private_ip}\"",
      "ssh -i private.pem $OPTS -o \"$PROXYCMD\" \"$SERVER\"",
      ""
    ])
    filename = "${path.module}/jump.sh"
  }

' >>resources.tf
