
######################################################################
# iam_db_auth.tpl — Commented template
#
# This file provides an EC2 user-data script to prepare an
# instance to authenticate to an RDS MySQL-compatible instance using
# IAM DB authentication, and to create an application user that uses
# IAM authentication instead of long-lived DB credentials.
######################################################################

#!/bin/bash

# Update package lists
sudo yum update -y

# Install MariaDB 10.5 client as MySQL client replacement
sudo dnf install -y mariadb105

# Remove AWS CLI v1 if installed
sudo yum remove awscli

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install and start the SSM Agent
sudo yum install -y amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl status amazon-ssm-agent

# Variables to hold RDS connection details  
# values from Terraform variables and output.tf (to be replaced during provisioning)
db_ept=${db_endpoint}
region_db=${region}
username_db=${db_username}
port_db=${db_port}

# Generate IAM authentication token and connect to RDS
TOKEN=$(aws rds generate-db-auth-token \
  --hostname $db_ept \
  --port $port_db \
  --region $region_db \
  --username $username_db)

# Connect to the RDS instance using the token
mysql -h $db_ept -u $username_db --enable-cleartext-plugin --password=$TOKEN <<EOF
-- Create appuser with IAM authentication
CREATE USER 'appuser'
IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';

-- Grant necessary privileges to appuser
GRANT SELECT, INSERT, UPDATE, DELETE
ON alloydb.*
TO 'appuser';

-- Apply changes
FLUSH PRIVILEGES;

-- Cleanup: Remove privileges from masteruser
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'masteruser';
EOF

