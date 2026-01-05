/*
Secure S3 + DynamoDB remote state backend example.

Before enabling this backend:
- Create the S3 bucket with server-side encryption enabled and Block Public Access turned on.
- Create the DynamoDB table (primary key `LockID`) for state locking.
- Ensure the IAM principal used by Terraform has permission to access the S3 bucket and the DynamoDB table.

Replace the `bucket` and `dynamodb_table` values below with your production resources.
*/

# terraform {
# 	backend "s3" {
# 		bucket         = "REPLACE_WITH_STATE_BUCKET"        # e.g. my-terraform-state-production
# 		key            = "global/terraform.tfstate"         # path within the bucket
# 		region         = "us-east-1"                        # bucket region
# 		encrypt        = true                                 # server-side encryption for objects
# 		dynamodb_table = "REPLACE_WITH_DYNAMODB_TABLE"      # e.g. terraform-state-locks
# 		acl            = "private"
# 		# Optional: if you need to assume a role for backend access, set `role_arn` here.
# 		# role_arn = "arn:aws:iam::123456789012:role/terraform-backend-role"
# 	}
# }

/*
Recommended minimal IAM permissions for the backend principal:

 - s3:ListBucket on the state bucket
 - s3:GetObject, s3:PutObject, s3:DeleteObject on the state key(s)
 - s3:GetEncryptionConfiguration on the bucket
 - dynamodb:GetItem, PutItem, DeleteItem, UpdateItem, Query on the lock table

Do NOT commit real backend credentials or a local `terraform.tfstate` file into source control.
*/
