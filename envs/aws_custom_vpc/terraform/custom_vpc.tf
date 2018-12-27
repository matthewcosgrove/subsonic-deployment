variable "aws_vpc_name"   { default = "subsonic"} # Name of your VPC                         (required)

variable "aws_region"     { default = "us-east-2" } # AWS Region
output "aws.network.region" {
  value = "${var.aws_region}"
}

variable "network"        { default = "10.4" }      # First 2 octets of your /16
output "aws.network.prefix" {
  value = "${var.network}"
}

variable "aws_az1"        { default = "a" }
variable "aws_az2"        { default = "b" }
variable "aws_az3"        { default = "c" }
output "dmz_az" {
  value = "${var.aws_az1}"
}

data "aws_availability_zones" "available" {}

provider "aws" {
}

###############################################################

resource "aws_vpc" "default" {
  cidr_block           = "${var.network}.0.0/16"
  enable_dns_hostnames = "true"
  tags { Name = "${var.aws_vpc_name}" }
}



########   #######  ##     ## ######## #### ##    ##  ######
##     ## ##     ## ##     ##    ##     ##  ###   ## ##    ##
##     ## ##     ## ##     ##    ##     ##  ####  ## ##
########  ##     ## ##     ##    ##     ##  ## ## ## ##   ####
##   ##   ##     ## ##     ##    ##     ##  ##  #### ##    ##
##    ##  ##     ## ##     ##    ##     ##  ##   ### ##    ##
##     ##  #######   #######     ##    #### ##    ##  ######

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}
resource "aws_route_table" "external" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
  tags { Name = "${var.aws_vpc_name}-external" }
}

 ######  ##     ## ########  ##    ## ######## ########  ######
##    ## ##     ## ##     ## ###   ## ##          ##    ##    ##
##       ##     ## ##     ## ####  ## ##          ##    ##
 ######  ##     ## ########  ## ## ## ######      ##     ######
      ## ##     ## ##     ## ##  #### ##          ##          ##
##    ## ##     ## ##     ## ##   ### ##          ##    ##    ##
 ######   #######  ########  ##    ## ########    ##     ######

###############################################################
# DMZ - De-militarized Zone for NAT box ONLY
#
resource "aws_subnet" "dmz" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.0.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-dmz" }
}
resource "aws_route_table_association" "dmz" {
  subnet_id      = "${aws_subnet.dmz.id}"
  route_table_id = "${aws_route_table.external.id}"
}
output "aws.network.dmz.subnet" {
  value = "${aws_subnet.dmz.id}"
}
output "aws.network.dmz.az" {
  value = "${var.aws_region}${var.aws_az1}"
}

 ######  ########  ######          ######   ########   #######  ##     ## ########   ######
##    ## ##       ##    ##        ##    ##  ##     ## ##     ## ##     ## ##     ## ##    ##
##       ##       ##              ##        ##     ## ##     ## ##     ## ##     ## ##
 ######  ######   ##              ##   #### ########  ##     ## ##     ## ########   ######
      ## ##       ##              ##    ##  ##   ##   ##     ## ##     ## ##              ##
##    ## ##       ##    ## ###    ##    ##  ##    ##  ##     ## ##     ## ##        ##    ##
 ######  ########  ######  ###     ######   ##     ##  #######   #######  ##         ######

resource "aws_security_group" "dmz" {
  name        = "dmz"
  description = "Allow services from the private subnet through NAT"
  vpc_id      = "${aws_vpc.default.id}"
  tags { Name = "${var.aws_vpc_name}-dmz" }

  # ICMP traffic control
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow SSH traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow cf ssh traffic
  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow bosh registry traffic into the NAT box
  ingress {
    from_port   = 6868
    to_port     = 6868
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all traffic through the NAT from inside the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.network}.0.0/16"]
  }


  # ICMP traffic control (outbound)
  # Allows diagnostic utilities like ping / traceroute
  # to function as expected, and aid in troubleshooting.
  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow *ALL* outbound TCP traffic.
  # (security ppl may not like this...)
  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow *ALL* outbound UDP traffic.
  # (security ppl may not like this...)
  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
