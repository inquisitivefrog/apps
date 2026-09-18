variable "aws_region" {
  description = "AWS region for the state backend itself. Should match the main config's region for locality, though S3/DynamoDB work fine cross-region if ever needed."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to authenticate with (see ~/.aws/credentials). Never hardcode credentials in .tf files or .tfvars."
  type        = string
  default     = "grid-meter"
}

variable "project_name" {
  description = "Short project identifier, used to build globally-unique resource names (S3 bucket names are global across all AWS accounts)."
  type        = string
  default     = "grid-meter-app"
}
