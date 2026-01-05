/*
Purpose: Define EC2 compute resources used by the application. Includes
         instance create-time settings, IMDS configuration, EBS encryption,
         and instance profile attachment for least-privilege access.

Security notes:
 - Instances are launched in private subnets with no public IP assigned.
 - IMDSv2 is enforced via `metadata_options.http_tokens = "required"`.
 - Root EBS volumes are encrypted with the project's KMS key.
 - Use SSM for management (no SSH) and attach only required IAM policies.
*/

# data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# EC2 Instance in Private Subnet with IAM Role, Encrypted EBS, SSM-Only Access, IMDSv2 
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = false
    
  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
    kms_key_id = aws_kms_key.main.arn
  }

  user_data = data.template_file.iam_db_auth.rendered

  tags = {
    Name = "${var.project}-app"
  }

  depends_on = [ aws_db_instance.db ]
}
