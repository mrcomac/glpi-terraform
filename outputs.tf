output "glpi_address" {
  value = "${aws_route53_record.glpi.name}.${var.domain_name}"
}
