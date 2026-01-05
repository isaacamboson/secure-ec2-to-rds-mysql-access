/*
Purpose: Create VPC Interface Endpoints (AWS PrivateLink) for SSM-related
         services so EC2 instances can access management APIs without
         traversing the public internet.

Security notes:
 - Interface endpoints keep traffic inside the AWS network and improve
   security posture by removing the need for public egress for management
   traffic.
 - Use endpoint-specific security groups to control which instances can
   reach the endpoint (see `aws_security_group.ssm_endpoint_sg`).
*/

resource "aws_vpc_endpoint" "ssm_endpoints" {
  # Use a 'for_each' loop to create all three required endpoints efficiently
  for_each          = toset(["ssm", "ssmmessages", "ec2messages"])
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true # Recommended to use AWS PrivateLink for automatic DNS resolution
  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
  subnet_ids         = [aws_subnet.private[0].id] # Associate with private subnets where ec2 instance resides

  tags = {
    Name = "${var.project}-vpce-ssm-${each.key}"
  }
}