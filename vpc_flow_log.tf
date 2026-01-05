/*
Purpose: Configure VPC Flow Logs and an S3 destination bucket to capture
         network flow metadata for monitoring, incident response and audits.

Security notes:
 - Flow logs are stored in an S3 bucket with server-side encryption and
   public access blocked. Ensure the bucket policy only allows the VPC Flow
   Logs service to write objects.
 - Retention and lifecycle policies should be applied to control costs and
   to retain data according to compliance requirements.
*/

resource "aws_flow_log" "example_flow_log" {
  # The ID of the VPC (or Subnet/ENI) to monitor
  vpc_id = aws_vpc.main.id

  # The type of traffic to capture (ACCEPT, REJECT, ALL)
  traffic_type = "ALL"

  # The destination type (s3 or cloud-watch-logs)
  log_destination_type = "s3"

  # The ARN of the S3 bucket destination
  log_destination = aws_s3_bucket.vpc_flow_logs_bucket.arn

  tags = {
    Name = "${var.project}-vpc-flow-log"
    }
}

# S3 bucket for VPC Flow Logs
resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
  bucket = "${var.project}-vpc-flow-logs-s3"
} 

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs_bucket_encryption" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs_bucket_versioning" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs_bucket_public_access_block" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}   

resource "aws_s3_bucket_policy" "vpc_flow_logs_bucket_policy" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.vpc_flow_logs_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:vpc/*"
          }
        }
      }
    ]
  })
}  

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}
