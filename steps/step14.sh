#
# Append a default security group for our VPC to keep this workshop simple
#
echo '
  resource aws_security_group default {
    name = "workshop-default-security-group"
    vpc_id = aws_vpc.vpc.id
    egress {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
    }
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }
    egress {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = [ "${var.cidr_block}" ]
    }
  }
' >>vpc/resources.tf
