/*
Purpose: Create and manage KMS keys used to encrypt at-rest resources such
         as RDS storage and EBS volumes.

Security notes:
 - Key rotation is enabled; ensure rotation and key policies meet your
   organizational requirements.
 - Limit key usage via IAM and KMS key policies to prevent unauthorized
   encryption/decryption operations.
 - Deletion window is configured to avoid accidental immediate key deletion.
*/

# KMS Key for encrypting RDS and EBS volumes with key rotation enabled
resource "aws_kms_key" "main" {
  description             = "KMS key for RDS and EC2 encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

# KMS Alias for easier identification
resource "aws_kms_alias" "main_alias" {
  name          = "alias/${var.project}-main-key"
  target_key_id = aws_kms_key.main.key_id
}
