variable "aws_region" {
  description = "AWS region for project resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "AWS VPC CIDR for project resources"
  type        = string
  default     = "10.0.0.0/16"
}