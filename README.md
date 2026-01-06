# Secure AWS EC2 to RDS — Terraform Infrastructure

This repository defines an AWS infrastructure using Terraform. It is organized as a collection of top-level Terraform files (for example `main.tf`, `vpc.tf`, `rds.tf`, `ec2.tf`, `iam.tf`, `kms.tf`, `security.tf`, `vpc_endpoint.tf`, `vpc_flow_log.tf`, `backend.tf`, etc.) which together provision a secure, production-ready VPC-based environment with compute and database resources.

**Repository layout (high level)**
- `backend.tf`: Terraform backend configuration (state storage/locking).
- `provider.tf`: Provider configuration and required provider versions.
- `versions.tf`: Terraform required version and module constraints.
- `variables.tf`: Project-wide variables and defaults.
- `main.tf`: Top-level orchestration, module usage and resource composition.
- `vpc.tf`: VPC definition, subnets, route tables and CIDR layout.
- `vpc_endpoint.tf`: VPC endpoints to avoid public traffic for AWS services.
- `vpc_flow_log.tf`: VPC Flow Logs configuration to capture network flow data.
- `security.tf`: Security Groups, NACLs (if present), and network access rules.
- `ec2.tf`: EC2 instances, ASG or bastion/jump host definitions where applicable.
- `rds.tf`: RDS database instances, parameter groups, subnet groups and encryption settings.
- `iam.tf` + `iam_db_auth.tpl`: IAM roles, policies, and templates used for DB IAM authentication.
- `kms.tf`: KMS key definitions used for encryption at rest of sensitive resources.
- `output.tf`: Outputs useful for downstream automation and debugging.
- `config.tf`, `kms.tf`, `security.tf`: Supporting configuration files for environment specifics.

Purpose and intent
------------------
This Terraform project is intended to create a secure AWS networking and service footprint suitable for hosting application compute and a managed database. The design focuses on:
- Clear network segmentation (public/private subnets)
- Minimal public exposure and use of VPC endpoints
- Encryption in transit and at rest
- Principle of least privilege for IAM
- Audit and logging for network and operational visibility

How to use
----------
1. Review and set required variables in a `variables.tf` or through environment variables.
2. Initialize Terraform:

```bash
terraform init
```

3. Preview changes:

```bash
terraform plan -out=tfplan
```

4. Apply changes:

```bash
terraform apply "tfplan"
```

5. To tear down:

```bash
terraform destroy
```

State management
----------------
The project includes a `backend.tf` file to centralize Terraform state. In production you should configure a remote, durable backend (for example S3 with DynamoDB state locking) rather than using local state. Remote state ensures team coordination, locking, and recoverability.

Security design details:
-------------------------
This section explains the project's security posture, decisions and recommendations.

1) Network segmentation and isolation
- Subnets: The VPC is split between public subnets and private subnets for application servers and databases. Resources storing or accessing sensitive data (RDS) live in private subnets with no direct internet route. 
- Route tables: Public subnets have routes to an Internet Gateway only when necessary, and private subnets use NAT gateways (or NAT instances) to reach the internet for package updates while keeping inbound access blocked. RDS may reach out to the internet for pulling patches, updates etc while ec2 needed to update linux packages, install SSM and download mysql client during bootstrap so as to connect to mysql database in RDS.

2) Minimizing public exposure
- Bastion / jump host pattern: If direct SSH to private instances is required, use a hardened bastion host in a public subnet and restrict SSH access to a small set of admin IPs.
- Security groups: Stateful firewall rules are applied using security groups. Only required ports are opened and rules are scoped to specific source security groups or CIDR ranges.
- No wide-open rules: Avoid `0.0.0.0/0` for administrative ports (SSH, RDS DB ports). Use narrow CIDR ranges or AWS SSO/VPN for administrative access.

3) VPC endpoints and private access
- VPC endpoints (interface and gateway endpoints) are used to route traffic to AWS services (Systems Manager) without traversing the public internet. See `vpc_endpoint.tf`. EC2 instance in private subnet can be connected to using SSM with using SSH via public internet.

4) Encryption in transit and at rest
- Encryption at rest: KMS keys defined in `kms.tf` are used to encrypt storage-backed resources (RDS, EBS volumes, S3 buckets where applicable). Ensure KMS keys have key policies and IAM usage limited to required roles.
- Encryption in transit: RDS and application layers should be configured to use TLS where supported. For RDS, provide and enforce TLS connections from app servers.

5) IAM and least privilege
- Roles and Policies: IAM roles and policies are defined in `iam.tf`. The principle of least privilege is applied — roles grant only the permissions needed for a component to function. Enforce least-privilege IAM (no wildcards), separate provisioning and runtime roles, require MFA for console roles, and scope `rds-db:connect` ARNs to specific DB/user combos. Use IAM Access Analyzer to surface overly-broad policies.
- Instance Profiles: EC2 instances use instance profiles scoped tightly to limit access to AWS APIs (for example only allow SSM and read-only S3 if required).
- RDS IAM Authentication: This is included in the bootstrap user data file `iam_db_auth.tpl` which indicates support for IAM DB authentication; this reduces the need for stored DB credentials and enables temporary, auditable credentials.

6) Secrets management
- Secrets are not be stored in plain Terraform variables. We use Secrets Manager and SSM Parameter Store with encryption enabled and reference them securely at deployment.

7) Logging, monitoring and auditability
- VPC Flow Logs: `vpc_flow_log.tf` configures VPC Flow Logs to capture network traffic metadata. Flow logs help detect suspicious traffic and support incident investigations.
- Centralized logging: Route logs to CloudWatch Logs or a centralized S3 bucket and configure retention and lifecycle policies.
- Terraform state security: State files can contain sensitive data. Ensure state files in S3 are encrypted with KMS and access is restricted.

8) KMS key lifecycle & rotation
- KMS Keys should have key rotation enabled where supported and restricted administrative access. Define key aliasing and clear key policy ownership.

9) Compliance & best practices
- Use MFA and role-based access for AWS Console access.
- Enforce Guardrails: Apply AWS Organizations SCPs where appropriate to restrict risky API usage.
 

 
 