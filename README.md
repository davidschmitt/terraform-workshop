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

11. Here is an overview of the files we created so far.  They will remain after the workshop in case
you want to review them.

```
$ ls -lR
```

12. Actually apply the configuration to create an empty VPC
The -auto-approve flag avoids the need for you to type 'yes<ENTER>'

```
$ terraform apply -auto-approve
```

13. Append gateway and routing resources so we can talk to the Internet

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

14. Append a default security group for our VPC to keep this workshop simple

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

15. We will need some of the VPC resource information to create subnets later.
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

16. Go ahead and apply the changes

```
$ terraform apply -auto-approve
```

17. Now we'll create an availability zone child module and define the variables it will need

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

18. In order to avoid extra variables for the user to populate 
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

19. Define local values to calculate an az_name offset.
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

20. Add a public subnet resource.  We use the offset to calculate CIDR blocks
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

21. Add the az child module to our root module

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

22. Since we have added a new child module we must re-run terraform init

```
$ terraform init
```

23. Go ahead and create the public subnet

```
$ terraform apply -auto-approve
```

24. We will need a NAT instance for our private subnet

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

25. Define a route table for the private subnet to use
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

26. Define the private subnet

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

27. Go ahead and create the NAT and private subnet

```
$ terraform apply -auto-approve
```

28. Define extra variables in the root module for our second VPC

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

29. Add the second VPC values to the terraform.tfvars file

```
$ echo '
  cidr_block_2  = "10.2.0.0/16"
  region_2      = "us-east-1"
' >>terraform.tfvars
```

30. Add the second provider alias to the root module

```
$ echo '
  provider aws {
    region  = var.region_2
    alias   = "aws_2"
  }
' >>providers.tf
```

31. Add the second VPC and second AZ to the root module.
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

32. Since we added two new child modules we must run init again

```
$ terraform init
```

33. Actually create the second VPC and AZ

```
$ terraform apply -auto-approve
```

34. In order to employ the subnets from the AZs we need to export their ID values from the child module.
We also need the private route table for VPC peering.
We export the NAT ami ID to use for a bastion host and internal server later on (even though
they won't be actual NAT instances)

```
$ echo '
  output public_subnet_id {
    value = aws_subnet.public.id
  }
  output private_subnet_id {
    value = aws_subnet.private.id
  }
  output private_route_table_id {
    value = aws_route_table.private.id
  }
  output nat_ami_id {
    value = data.aws_ami.nat_ami.id
  }
' >az/outputs.tf
```

35. We want to peer our two VPCs.  Here we create a new child module for peering and describe its variables

```
$ mkdir -p ./peering && echo '
  variable requester_id {
    type = string
    description = "The id of the requester vpc"
  }
  variable requester_route_table_ids {
    type = list(string)
    description = "A list of route table ids to which the accepter CIDR block should be added"
  }
  variable accepter_id {
    type = string
    description = "The id of the accepter vpc"
  }
  variable accepter_route_table_ids {
    type = list(string)
    description = "A list of peer route table ids to which the requester CIDR block should be added"
  }
  variable tags {
    type = map(string)
    description = "General tags to apply to all resources"
  }
' >peering/vars.tf
```

36. Peering requires resources in two differnt VPCs.  Declare a provider for each
(these will be passed from the root module)

```
$ echo '
  provider aws {
    alias = "requester"
  }
  provider aws {
    alias = "accepter"
  }
' >peering/providers.tf
```

37. Use provider data sources to find extra info for peering.
Notice that we use the two separate AWS providers - one for each VPC

```
$ echo '
  data aws_vpc requester {
    provider = aws.requester
    id = var.requester_id
  }
  data aws_vpc accepter {
    provider = aws.accepter
    id = var.accepter_id
  }
  data aws_region accepter {
    provider = aws.accepter
  }
  data aws_caller_identity accepter {
    provider = aws.accepter
  }
' >peering/data.tf
```

38. Now we can declare the actual peering

```
$ echo '
  resource aws_vpc_peering_connection requester {
    provider = aws.requester
    vpc_id = var.requester_id
    peer_vpc_id = var.accepter_id
    peer_region = data.aws_region.accepter.name
    peer_owner_id = data.aws_caller_identity.accepter.account_id
    auto_accept = false
    tags = merge(var.tags, { 
      Name = "workshop-peering"
    })
  }
  resource aws_vpc_peering_connection_accepter accepter {
    provider = aws.accepter
    vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
    auto_accept = true
    tags = merge(var.tags, { 
      Name = "workshop-peering"
    })
  }
' >peering/resources.tf
```

39. Add routes between the peered VPCs
Notice how we use the count mechanism to create more than one route at a time

```
$ echo '
  resource aws_route vpc_routes {
    count = length(var.requester_route_table_ids)
    provider = aws.requester
    route_table_id = var.requester_route_table_ids[count.index]
    destination_cidr_block = data.aws_vpc.accepter.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
  }
  resource aws_route peer_routes {
    count = length(var.accepter_route_table_ids)
    provider = aws.accepter
    route_table_id = var.accepter_route_table_ids[count.index]
    destination_cidr_block = data.aws_vpc.requester.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
  }
' >>peering/resources.tf
```

40. In the root module, use the peering sub-module to actually establish peering

```
$ echo '
  module peering_1_2 {
    source                    = "./peering"
    tags                      = var.tags
    requester_id              = module.vpc_1.vpc_id
    accepter_id               = module.vpc_2.vpc_id
    requester_route_table_ids = [ 
      module.vpc_1.public_route_table_id,
      module.az_1.private_route_table_id
    ]
    accepter_route_table_ids  = [
      module.vpc_2.public_route_table_id,
      module.az_2.private_route_table_id
    ]
    providers                 = {
      aws.requester = aws.aws_1
      aws.accepter = aws.aws_2
    }
  }
' >>modules.tf
```

41. Since we added a new sub-module we must re-run terraform init

```
$ terraform init
```

42. Actually apply the peering changes

```
$ terraform apply -auto-approve
```

43. We want to attach a key pair so that you can test connectivity to the bastion host and internal server

```
$ echo '
  variable key_pair {
    type = string
    description = "The name of a key pair to attach to a bastion host and internal server for testing purposes"
  }
' >>vars.tf
```

44. Enter the name of the key pair you want to use (we can't provide it to you)

```
$ echo -n "Please enter the name of the key pair you wish to use: " &&
read KEY_PAIR &&
echo "
  key_pair      = \"$KEY_PAIR\"
" >>terraform.tfvars
```

45. The EC2 resources here are not re-usable, so we just put them in the root module
We could use count here if we wanted a separate bastion for each VPC

```
$ echo '
  resource aws_instance bastion {
    provider                    = aws.aws_1
    associate_public_ip_address = true
    instance_type               = "t2.nano"
    key_name                    = var.key_pair
    ami                         = module.az_1.nat_ami_id
    subnet_id                   = module.az_1.public_subnet_id
    vpc_security_group_ids      = [ module.vpc_1.default_security_group_id ]
    tags = merge(var.tags, { 
      Name = "workshop-bastion"
    })
  }
' >resources.tf
```

46. Since we have peered the VPCs we can access this internal server
via the bastion in the other VPC

```
$ echo '
  resource aws_instance server {
    provider                    = aws.aws_2
    instance_type               = "t2.nano"
    key_name                    = var.key_pair
    ami                         = module.az_2.nat_ami_id
    subnet_id                   = module.az_2.private_subnet_id
    vpc_security_group_ids      = [ module.vpc_2.default_security_group_id ]
    tags = merge(var.tags, { 
      Name = "workshop-server"
    })
  }
' >>resources.tf
```

47. Apply the changes to create the servers

```
$ terraform apply -auto-approve
```

48. Here is an overview of the files we created.  They will remain after the workshop in case
you want to review them.
The terraform.tfstate* files are where Terraform tracks internal state so you should never
modify or remove those files while you have active resources.

```
$ ls -lR
```

49. Now that this workshop is done clean up after ourselves and destroy all the resources

```
$ terraform destroy -auto-approve
```

