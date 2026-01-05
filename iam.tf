/*
Purpose: Define IAM roles, instance profiles and policies used by EC2 and
         other resources. This file scopes AWS API access to the minimum
         permissions required and enables RDS IAM authentication integration.

Security notes:
 - Apply the principle of least privilege to all policies and avoid wildcards
   when possible.
 - Use managed policies sparingly; prefer scoped inline or custom policies
   that limit access to only necessary resources.
 - Rotate credentials for long-lived keys and use instance profiles for EC2.
*/

# IAM Policy Document for EC2 Assume Role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM role with Least Privilege for EC2 to access RDS with IAM Authentication
resource "aws_iam_role" "ec2_role" {
  name = "${var.project}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# SSM Access for EC2 Instances (No SSH Required)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Policy for RDS IAM Authentication
resource "aws_iam_policy" "rds_iam_auth" {
  name = "${var.project}-rds-iam-auth"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "rds-db:connect"
      ]
    #   Resource = "*"
      Resource = "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.db.resource_id}/${var.db_username}"
    #   Resource = "arn:aws:rds:${var.region}:${data.aws_caller_identity.current.account_id}:db:${aws_db_instance.db.resource_id}"
    #   Resource = aws_db_instance.db.arn
    }]
  })
}

# Attach RDS IAM Auth Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "rds" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.rds_iam_auth.arn
}

# IAM Instance Profile for EC2 Instances
resource "aws_iam_instance_profile" "ec2_profile" {
  role = aws_iam_role.ec2_role.name
}

# IAM Policy to allow EC2 to read specific secret from Secrets Manager
resource "aws_iam_policy" "secrets_read" {
  name        = "ec2-read-specific-secret"
  description = "Allow EC2 to read a specific secret from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_db_instance.db.master_user_secret[0].secret_arn
      }
    ]
  })
}

# Attach Secrets Read Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "secret_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_read.arn
}
