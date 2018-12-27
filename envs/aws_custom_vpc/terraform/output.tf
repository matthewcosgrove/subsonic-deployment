output "subnet_id" {
    value = "${aws_subnet.dmz.id}"
}

output "subnet_prefix" {
    value = "${var.network}"
}

output "subnet_az" {
    value = "${var.aws_region}${var.aws_az1}"
}

output "security_group" {
    value = "${aws_security_group.dmz.name}"
}
