/*
Purpose: Define input variables for the Terraform project including defaults
         for VPC CIDRs, availability zones, and database configuration.

Security notes:
 - Avoid hard-coding sensitive values (passwords, secrets) here. Use
   external secret managers (Secrets Manager, SSM Parameter Store) or
   CI-provided secure variable injection.
 - Review default CIDR and AZ lists to ensure they match your intended
   isolation and availability requirements.
*/

variable "region" {
    description = "The AWS region to deploy resources in."
    type        = string
    default = "us-east-1"
}

variable "vpc_cidr" {
    description = "The CIDR block for the VPC."
    type        = string
    default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type = list(string)
  default     = [
    "10.0.5.0/24", 
    "10.0.6.0/24"
  ]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type = list(string)
  default     = [
    "10.0.1.0/24", 
    "10.0.2.0/24", 
    "10.0.3.0/24", 
    "10.0.4.0/24"
  ]
}

variable "azs" {
  description = "List of availability zones"
  type = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "project" {
    type        = string
    default = "alloy"
}

variable "db_name" {
    type        = string
    default = "alloydb"
}

variable "db_username" {
    description = "The username for the database."
    type        = string
    default = "masteruser"
}

variable "db_port" {
    description = "The port on which the database will listen."
    type        = number
    default     = 3306  
}

