# Amazon RDS for MySQL.
#
# Security:
#   - private, isolated database subnets; publicly_accessible = false
#   - security group allows 3306 only from the EKS node security group, no egress
#   - storage encrypted at rest
#   - master password generated and stored by RDS in AWS Secrets Manager
#     (never appears in Terraform code or variables; see master_user_secret_arn)
#
# Cost:
#   - db.t4g.micro, 20 GiB gp3 (autoscaling capped), single-AZ by default
#   - 1 day of backups, no Performance Insights, no enhanced monitoring

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-rds-"
  description = "MySQL access from EKS nodes only"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.name}-rds" }
}

resource "aws_vpc_security_group_ingress_rule" "mysql_from_nodes" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = var.allowed_security_group_id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  description                  = "MySQL from EKS nodes"
}

resource "aws_db_instance" "this" {
  identifier = "${var.name}-mysql"

  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.max_allocated_storage_gb
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period    = var.backup_retention_days
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  apply_immediately          = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-mysql-final"

  performance_insights_enabled = false

  tags = { Name = "${var.name}-mysql" }
}
