variable "aws_region" {
  description = "AWS region for the state backend itself. Must be us-east-2 for this account specifically - confirmed live (2026-10-06) that an AWS Organizations SCP (arn:aws:organizations::979700392224:policy/o-ehxoc2g98d/service_control_policy/p-72raajd7, applied by this account's org - likely the free-tier/credits program's own management account, not something this account's own IAM can see or override) explicitly denies EC2/S3 operations in us-east-1 and us-west-2 for this account, but allows us-east-2 - confirmed via a live ec2:DescribeVpcs probe (explicit SCP deny in both blocked regions, success in us-east-2, returning a real pre-existing default VPC) before changing this default."
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to authenticate with (see ~/.aws/credentials). Never hardcode credentials in .tf files or .tfvars. This bootstrap targets the separate, newer 'free tier' AWS account (184375956348) created specifically for low-cost interview-cycle hosting - see terraform/aws/bootstrap/ for the original account's (084375569056) now-unused bootstrap."
  type        = string
  default     = "grid-meter-freetier"
}

variable "project_name" {
  description = "Short project identifier, used to build globally-unique resource names (S3 bucket names are global across all AWS accounts)."
  type        = string
  default     = "grid-meter-app"
}
