/*
Purpose: Define Security Groups used to control network access between
         EC2 instances, RDS and VPC endpoints. Security groups are stateful
         and should be narrowly scoped to only allow necessary traffic.

Security notes:
 - Avoid wide-open ingress rules; prefer referencing security groups
   (e.g., allow app security group to reach DB security group) rather than
   using CIDR ranges when possible.
 - Egress is currently permissive for convenience; consider locking egress
   down in higher-security environments to specific destinations.
 - SSM VPC endpoint security group restricts traffic to the VPC CIDR on
   port 443 to limit who can reach the endpoint.
*/

# security group for EC2
resource "aws_security_group" "ec2_sg" {
  name   = "${var.project}-ec2-sg"
  vpc_id = aws_vpc.main.id  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# security group for RDS
resource "aws_security_group" "db_sg" {
  name   = "${var.project}-db-sg"
    vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# security group for SSM VPC endpoints
resource "aws_security_group" "ssm_endpoint_sg" {
  name        = "ssm-vpc-endpoint-sg"
  description = "Security group for SSM VPC endpoints"
  vpc_id      = aws_vpc.main.id

  # Ingress from within the VPC on port 443
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic (default, but explicit for clarity)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}