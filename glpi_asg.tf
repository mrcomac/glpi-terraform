
resource "aws_launch_configuration" "lt-glpi" {
  name_prefix   = "${local.name_prefix}-asg-"
  image_id      = data.aws_ami.glpi.id
  instance_type = local.instance_size
  security_groups = [ aws_security_group.glpi.id ]
  key_name = var.key_par
  user_data = templatefile("${path.module}/glpi_launch.tmpl",{
    DB_HOST = data.external.snapshot_exists.result.SnapshotExists == "true" ? aws_db_instance.glpi_rds_from_snapshot[0].address : aws_db_instance.glpi_rds_new[0].address, #aws_instance.glpi_db_instance.private_dns,
    DB_USER= var.db_user,
    DB_PASSWORD= var.db_password,
    DB_NAME= var.db_name
    })

}

resource "aws_autoscaling_group" "asg-glpi" {
  vpc_zone_identifier =  module.vpc.private_subnet_ids
  name_prefix   = "${local.name_prefix}-asg-"
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  target_group_arns     = [aws_lb_target_group.tg_glpi.arn]
  health_check_type     = "ELB"
  default_cooldown      = "60"

  launch_configuration   = aws_launch_configuration.lt-glpi.id
  tags = [
    {
      "key"                 = "Name"
      "value"               = "${local.name_prefix}-asg-auto"
      "propagate_at_launch" = true
    },
     {
       "key"                 = "ProjectOwner"
       "value"               = var.project_owner
       "propagate_at_launch" = true
     },
     {
       "key"                 = "GeneratedBy"
       "value"               = "terraform"
       "propagate_at_launch" = true
     },
     {
       "key"                 = "Environment"
       "value"               = terraform.workspace
       "propagate_at_launch" = true
     },
     {
       "key"                 = "App"
       "value"               = var.app
       "propagate_at_launch" = true
     },
     {
       "key"                 = "GitRevision"
       "value"               = var.git_revision
       "propagate_at_launch" = true
     }]



}

#padding_policy
resource "aws_autoscaling_policy" "scaleUP" {
  name                   = "${local.name_prefix}-policy-UP"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg-glpi.name
}

resource "aws_autoscaling_policy" "scaleDOWN" {
  name                   = "${local.name_prefix}-policy-DOWN"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg-glpi.name
}

resource "aws_cloudwatch_metric_alarm" "CPU-Alarm-DOWN" {
  alarm_name          = "${local.name_prefix}-CPU-Alarm-DOWN"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg-glpi.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.scaleDOWN.arn ]
}

resource "aws_cloudwatch_metric_alarm" "CPU-Alarm-UP" {
  alarm_name          = "${local.name_prefix}-CPU-Alarm-UP"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg-glpi.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.scaleUP.arn ]
}
