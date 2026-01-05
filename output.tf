output "rds_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "rds_arn" {
  value = aws_db_instance.db.arn
}

output "rds_resource_id" {
    value = aws_db_instance.db.resource_id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  value = aws_vpc.main.arn
}

