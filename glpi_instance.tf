#search the AMI instead of get from packer because you can separately run packer and terraform
data "aws_ami" "glpi" {
  most_recent = true
  filter {
    name   = "name"
    values = [var.ami_packer_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = [var.ami_owner]
}

resource "aws_instance" "glpi" {
  ami           = data.aws_ami.glpi.id
  instance_type = local.instance_size
  subnet_id =  module.vpc.public_subnet_ids[0]
  count = data.external.snapshot_exists.result.SnapshotExists == "true" ? 0 : 1
  key_name = var.key_par
  associate_public_ip_address = true
  vpc_security_group_ids  = [ aws_security_group.glpi.id ]
  instance_initiated_shutdown_behavior = "terminate"
  user_data     = templatefile("${path.module}/glpi_deploy.tmpl", {
    DB_HOST     =  data.external.snapshot_exists.result.SnapshotExists == "true" ? aws_db_instance.glpi_rds_from_snapshot[count.index].address : aws_db_instance.glpi_rds_new[count.index].address, #aws_instance.glpi_db_instance.private_dns,
    DB_USER     = var.db_user,
    DB_PASSWORD = var.db_password,
    DB_NAME     = var.db_name
    })
  tags = merge({
    Name = "${local.name_prefix}-app-teste"
  }, local.default_tags)

}

#just if you need todo a test
resource "aws_security_group_rule" "http_to_instance" {
  type                      = "ingress"
  from_port                 = 80
  to_port                   = 80
  protocol                  = "tcp"
  source_security_group_id  = aws_security_group.lb_sg.id
  security_group_id         = aws_security_group.glpi.id
}


resource "aws_security_group" "glpi" {
    name        = "${local.name_prefix}-app-sg"
    description = "Security group for GLPI host"
    vpc_id      = module.vpc.vpc_id
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}
