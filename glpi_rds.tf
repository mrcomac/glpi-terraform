
data "external" "snapshot_exists" {
  program = ["bash", "-c", "if [ -z $(aws rds describe-db-snapshots --db-snapshot-identifier ${local.db_snapshot_final} --query DBSnapshots[*].{ID:DBSnapshotIdentifier} --out text 2> /dev/null) ]; then echo '{\"SnapshotExists\": \"false\"}'; else echo '{\"SnapshotExists\": \"true\"}'; fi"]
}

data "aws_db_snapshot" "db_snapshot" {
  count = data.external.snapshot_exists.result.SnapshotExists == "true" ? 1 : 0
    most_recent             = true
    db_instance_identifier  = "${local.name_prefix}-rds-${terraform.workspace}"
}

resource "aws_db_subnet_group" "glpi" {
  name       = "${local.name_prefix}-rds-${terraform.workspace}"
  subnet_ids =  module.vpc.private_subnet_ids
  tags       = local.default_tags
}

resource "aws_db_instance" "glpi_rds_new" {
  count                     = data.external.snapshot_exists.result.SnapshotExists == "true" ? 0 : 1
  allocated_storage         = 20
  identifier                = "${local.name_prefix}-rds-${terraform.workspace}"
  storage_type              = "gp2"
  engine                    = "mysql"
  engine_version            = "8.0.20"
  instance_class            = local.db_instance_size
  name                      = var.db_name
  username                  = var.db_user
  password                  = var.db_password
  vpc_security_group_ids    = [ aws_security_group.glpi_rds.id ]
  db_subnet_group_name      = aws_db_subnet_group.glpi.name
  maintenance_window        = "Mon:23:00-Tue:00:00"
  backup_window             = "00:01-01:00"
  backup_retention_period   = 7
  delete_automated_backups  = false
  final_snapshot_identifier = local.db_snapshot_final
  depends_on                = [ aws_db_subnet_group.glpi ]
  tags = merge({
    Name = "${local.name_prefix}-rds-${terraform.workspace}"
  }, local.default_tags)
}

resource "aws_db_instance" "glpi_rds_from_snapshot" {
  count                     = data.external.snapshot_exists.result.SnapshotExists == "true" ? 1 : 0
  allocated_storage         = 20
  identifier                = "${local.name_prefix}-rds-${terraform.workspace}"
  storage_type              = "gp2"
  engine                    = "mysql"
  engine_version            = "8.0.20"
  instance_class            = local.db_instance_size
  name                      = var.db_name
  username                  = var.db_user
  password                  = var.db_password
  vpc_security_group_ids    = [ aws_security_group .glpi_rds.id ]
  db_subnet_group_name      = aws_db_subnet_group.glpi.name
  maintenance_window        = "Mon:23:00-Tue:00:00"
  backup_window             = "00:01-01:00"
  backup_retention_period   = 7
  delete_automated_backups  = false
  final_snapshot_identifier = local.db_snapshot_final
  snapshot_identifier       = data.aws_db_snapshot.db_snapshot[0].id
  depends_on                = [ aws_db_subnet_group.glpi ]
  tags = merge({
    Name = "${local.name_prefix}-rds-${terraform.workspace}"
  }, local.default_tags)
}

resource "aws_security_group" "glpi_rds" {
  name        = "${local.name_prefix}-rds-sg-${terraform.workspace}"
  description = "Security group for GLPI RDS"
  vpc_id      = module.vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds_access" {
  type                      = "ingress"
  from_port                 = 3306
  to_port                   = 3306
  protocol                  = "tcp"
  source_security_group_id  = aws_security_group.glpi.id
  security_group_id         = aws_security_group.glpi_rds.id
}
