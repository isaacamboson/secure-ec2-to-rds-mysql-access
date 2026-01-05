/*
Purpose: Provision an RDS instance and DB subnet group. This file configures
         the managed database, enabling IAM authentication and encryption.

Security notes:
 - RDS instances are deployed to private subnets and are not publicly
   accessible (publicly_accessible = false).
 - Storage is encrypted using the project's KMS key (`aws_kms_key.main`).
 - IAM DB authentication is enabled to avoid long-lived DB credentials when
   possible; confirm application support for IAM tokens.
 - Security group rules must restrict access to the DB port to trusted
   application security groups only.
*/

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project}-db-subnets"
  subnet_ids = [aws_subnet.private[2].id, aws_subnet.private[3].id]
}

resource "aws_db_instance" "db" {
  identifier = "alloy-mysql-rds"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"  
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  manage_master_user_password = true

  iam_database_authentication_enabled = true

  storage_encrypted = true
  kms_key_id = aws_kms_key.main.arn

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  

  publicly_accessible     = false
#   backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true
  final_snapshot_identifier = "alloy-mysql-rds-final-snapshot"

  tags = {
    Security = "High"
    Auth     = "IAM"
  }
}
