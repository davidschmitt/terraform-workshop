# terraform-workshop

Demonstrate key features of Terraforms by incrementally moving from hello world VPC to fully usable public/private subnets in AWS.

# To initiate a live demo simply run:

```
$ bash run.sh
```
# Here are listed the actual steps that will be performed by the live demo:

1. Confirm that terraform is installed and in our path

```
$ terraform --version
```

2. Make sure "aws configure" has applied good credentials

```
$ aws sts get-caller-identity
```

3. Since we plan to have more than one VPC we want a reusable VPC module.
Here we create the VPC module directory and define the variables it needs

```
$ mkdir -p ./vpc && echo '
  variable tags {
    type        = map(string)
    description = "General tags to apply on all resources"
  }
  variable cidr_block {
    type        = string
    description = "The CIDR block of the VPC"
  }
' >vpc/vars.tf
```

4. Now we define the VPC resource in the child module based on the 
variables passed to it.
Notice how we merge the general tags with the Name tag

```
$ echo '
  resource aws_vpc vpc {
    cidr_block  = var.cidr_block
    tags        = merge(var.tags, {
      Name = "workshop-vpc"
    })
  }
' >vpc/resources.tf
```

5. Now we define some variables in our root level module.
As you might expect, we will be passing the cidr_block_1 value
into the VPC child module.

```
$ echo '
  variable tags {
    type        = map(string)
    description = "Tags we want to apply to all of our resources"
  }
  variable region_1 {
    type        = string
    description = "The AWS region of the first VPC"
  }
  variable cidr_block_1 {
    type        = string
    description = "The CIDR block of the first VPC"
  }
' >vars.tf
```

6. We create a terraform.tfvars file in our root module so that we won't
have to retype the variable values every time we run terraform.

```
$ echo '
  cidr_block_1  = "10.1.0.0/16"
  region_1      = "us-east-1"
  tags          = {
    Project = "Terraform Workshop Demo"
    Owner   = "me@example.com"
  }
' >terraform.tfvars
```

7. Define the provider in our root module that we will use for our first VPC

```
$ echo '
  provider aws {
    region  = var.region_1
    alias   = "aws_1"
  }
' >providers.tf
```

8. Wrap up our first example by using the VPC module to create our first VPC
Notice that the region is implied by the aws provider we pass

```
$ echo '
  module vpc_1 {
    source      = "./vpc"
    tags        = var.tags
    cidr_block  = var.cidr_block_1
    providers   = {
      aws = aws.aws_1
    }
  }
' >modules.tf
```

9. Tell Terraform to install the AWS provider plugin

```
$ terraform init
```

10. Validate our configuration files in case we made any mistakes

```
$ terraform validate
```

11. Actually apply the configuration to create an empty VPC
The -auto-approve flag avoids the need for you to type 'yes<ENTER>'

```
$ terraform apply -auto-approve
```

12. Append gateway and routing resources so we can talk to the Internet

```
$ echo '
  resource aws_internet_gateway igw {
    vpc_id = aws_vpc.vpc.id
    tags = merge(var.tags, {
      Name = "workshop-internet-gateway"
    })
  }
  resource aws_route_table public {
    vpc_id = aws_vpc.vpc.id
    tags = merge(var.tags, {
      Name = "workshop-public-route-table"
    })
  }
  resource aws_route default {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
' >>vpc/resources.tf
```

13. Append a default security group for our VPC to keep this workshop simple

```
$ echo '
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
```

14. We will need some of the VPC resource information to create subnets later.
Define the outputs so they will be available when we need them

```
$ echo '
  output vpc_id {
    value = aws_vpc.vpc.id
  }
  output public_route_table_id {
    value = aws_route_table.public.id
  }
  output default_security_group_id {
    value = aws_security_group.default.id
  }
' >vpc/outputs.tf
```

15. Go ahead and apply the changes

```
$ terraform apply -auto-approve
```

16. Now we'll create an availability zone child module and define the variables it will need

```
$ mkdir -p az && echo '
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
```

17. In order to avoid extra variables for the user to populate 
we use the AWS provider data sources to find values for us

```
$ echo '
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
```

18. Define local values to calculate an az_name offset.
That offset will be used to automatically calculate
subnet CIDR blocks.

```
$ echo '
  locals {
    region = data.aws_region.current.name
    azs = [
      "${local.region}a",
      "${local.region}b",
      "${local.region}c",
      "${local.region}d",
      "${local.region}e",
      "${local.region}f",
      "${local.region}g",
      "${local.region}h"
    ]
    offset = index(local.azs, var.az_name)
    cidr_block = data.aws_vpc.current.cidr_block
  }
' >az/locals.tf
```

19. Add a public subnet resource.  We use the offset to calculate CIDR blocks
that we know won't overlap.

```
$ echo '
  resource aws_subnet public {
    availability_zone = var.az_name
    cidr_block        = cidrsubnet(local.cidr_block, 4, local.offset * 2)
    vpc_id            = var.vpc_id
    tags              = merge(var.tags, {
      Name = "workshop-${var.az_name}-public-subnet"
    })
  }
  resource aws_route_table_association public {
    subnet_id       = aws_subnet.public.id
    route_table_id  = var.public_route_table_id
  }
' >>az/resources.tf
```

20. Add the az child module to our root module

```
$ echo '
  module az_1 {
    source                    = "./az"
    tags                      = var.tags
    az_name                   = "${var.region_1}a"
    vpc_id                    = module.vpc_1.vpc_id
    public_route_table_id     = module.vpc_1.public_route_table_id
    default_security_group_id = module.vpc_1.default_security_group_id
    providers                 = {
      aws = aws.aws_1
    }
  }
' >>modules.tf
```

21. Since we have added a new child module we must re-run terraform init

```
$ terraform init
```

22. Go ahead and create the public subnet

```
$ terraform apply -auto-approve
```

23. We will need a NAT instance for our private subnet

```
$ echo '
  resource aws_instance nat {
    ami                         = data.aws_ami.nat_ami.id
    instance_type               = "t2.nano"
    subnet_id                   = aws_subnet.public.id
    associate_public_ip_address = true
    vpc_security_group_ids      = [ var.default_security_group_id ]
    source_dest_check           = false
    tags                        = merge(var.tags, { 
      Name = "workshop-${var.az_name}-nat"
    })
  }
' >>az/resources.tf
```

24. Define a route table for the private subnet to use
with a default route via the NAT instance

```
$ echo '
  resource aws_route_table private {
    vpc_id  = var.vpc_id
    tags    = merge(var.tags, {
      Name = "workshop-${var.az_name}-private-route-table"
    })
  }
  resource aws_route private {
    destination_cidr_block  = "0.0.0.0/0"
    route_table_id          = aws_route_table.private.id
    instance_id             = aws_instance.nat.id
  }
' >>az/resources.tf
```

25. Define the private subnet

```
$ echo '
  resource aws_subnet private {
    vpc_id            = var.vpc_id
    availability_zone = var.az_name
    cidr_block        = cidrsubnet(local.cidr_block, 4, local.offset * 2 + 1)
    depends_on        = [ aws_instance.nat ]
    tags              = merge(var.tags, {
      Name = "workshop-${var.az_name}-private-subnet"
    })
  }
  resource aws_route_table_association private_nat_rt_assoc {
    subnet_id       = aws_subnet.private.id
    route_table_id  = aws_route_table.private.id
  }
' >>az/resources.tf
```

26. Go ahead and create the NAT and private subnet

```
$ terraform apply -auto-approve
```

27. Define extra variables in the root module for our second VPC

```
$ echo '
  variable region_2 {
    type        = string
    description = "The AWS region of the second VPC"
  }
  variable cidr_block_2 {
    type        = string
    description = "The CIDR block of the second VPC"
  }
' >>vars.tf
```

28. Add the second VPC values to the terraform.tfvars file

```
$ echo '
  cidr_block_2  = "10.2.0.0/16"
  region_2      = "us-east-1"
' >>terraform.tfvars
```

29. Add the second provider alias to the root module

```
$ echo '
  provider aws {
    region  = var.region_2
    alias   = "aws_2"
  }
' >>providers.tf
```

30. Add the second VPC and second AZ to the root module.
Notice how easy it is since child modules are reusable.

```
$ echo '
  module vpc_2 {
    source      = "./vpc"
    tags        = var.tags
    cidr_block  = var.cidr_block_2
    providers   = {
      aws = aws.aws_2
    }
  }
  module az_2 {
    source                    = "./az"
    tags                      = var.tags
    az_name                   = "${var.region_2}b"
    vpc_id                    = module.vpc_2.vpc_id
    public_route_table_id     = module.vpc_2.public_route_table_id
    default_security_group_id = module.vpc_2.default_security_group_id
    providers                 = {
      aws = aws.aws_2
    }
  }
' >>modules.tf
```

31. Since we added two new child modules we must run init again

```
$ terraform init
```

32. Actually create the second VPC and AZ

```
$ terraform apply -auto-approve
```

33. As a review, here are the files we created.
The terraform.tfstate* files are where Terraform tracks internal state so you should never
modify or remove those files while you have active resources.

```
$ ls -lR
```

34. Now that this workshop is done clean up after ourselves and destroy all the resources

```
$ terraform destroy -auto-approve
```

