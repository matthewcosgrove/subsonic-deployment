output "elastic_ip" {
    value = "${aws_eip.subsonic_eip.public_ip}"
}

output "default_subnet_id" {
    value = "${aws_default_subnet.default_az1.id}"
}

output "default_subnet_cidr" {
    value = "${aws_default_subnet.default_az1.cidr_block}"
}

output "default_subnet_az" {
    value = "${aws_default_subnet.default_az1.availability_zone}"
}

output "default_security_group" {
    value = "${aws_default_security_group.default.name}"
}
