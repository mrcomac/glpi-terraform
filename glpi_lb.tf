resource "aws_lb" "alb_glpi" {
  name               = "${local.name_prefix}-alb-${terraform.workspace}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection = false
  tags = local.default_tags

}

resource "aws_security_group" "lb_sg" {
  name        = "${local.name_prefix}-lb-sg"
  description = "Security group for GLPI Application LB"
  vpc_id      = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "redirect_http" {
  type                      = "ingress"
  from_port                 = 80
  to_port                   = 80
  protocol                  = "tcp"
  cidr_blocks               = [ "0.0.0.0/0" ]
  security_group_id         = aws_security_group.lb_sg.id
}

resource "aws_security_group_rule" "http_to_lb" {
  type                      = "ingress"
  from_port                 = 443
  to_port                   = 443
  protocol                  = "tcp"
  cidr_blocks               = [ "0.0.0.0/0" ]
  security_group_id         = aws_security_group.lb_sg.id
}

resource "aws_lb_target_group" "tg_glpi" {
  name     = "${local.name_prefix}-tg-${terraform.workspace}"
  port     = 80
  protocol = "HTTP"
  vpc_id   =  module.vpc.vpc_id
  stickiness {
    type            = "lb_cookie"
    cookie_duration = "60"
    enabled         = true

  }
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 10
    path                = "/"
    interval            = 30
    matcher = "200"
  }
  tags = local.default_tags
}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb_glpi.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "LBL-WebSite" {
  load_balancer_arn = aws_lb.alb_glpi.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn = aws_acm_certificate_validation.glpi.certificate_arn
  default_action {
    target_group_arn = aws_lb_target_group.tg_glpi.arn
    type             = "forward"
  }
}

#use only if you will run without autoscaling
#resource "aws_lb_target_group_attachment" "front_end" {
#  count    = length(aws_instance.glpi)
#  target_group_arn = aws_lb_target_group.tg_glpi.arn
#  target_id = aws_instance.glpi[count.index].id
#  port             = 80
#}
