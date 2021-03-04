data "aws_route53_zone" "glpi" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "glpi" {
  domain_name       = "${var.subdomain}.${var.domain_name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "glpi" {
  zone_id = data.aws_route53_zone.glpi.zone_id
  name    = "glpi"
  type    = "A"

  alias {
    name                   = aws_lb.alb_glpi.dns_name
    zone_id                = aws_lb.alb_glpi.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  for_each = {
    for dvo in aws_acm_certificate.glpi.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.glpi.zone_id


}

resource "aws_acm_certificate_validation" "glpi" {
  certificate_arn         = aws_acm_certificate.glpi.arn
  validation_record_fqdns = [for record in aws_route53_record.www : record.fqdn]
}
