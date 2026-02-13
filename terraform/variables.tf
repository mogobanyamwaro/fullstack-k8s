variable "aws_access_key_id" {
  description = "AWS Access Key ID (set in terraform.tfvars)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.aws_access_key_id) > 0
    error_message = "aws_access_key_id must not be empty."
  }
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key (set in terraform.tfvars)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.aws_secret_access_key) > 0
    error_message = "aws_secret_access_key must not be empty."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "fullstack-app"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "control_plane_instance_type" {
  description = "EC2 instance type for control plane (node 0) - min t3.small for K8s"
  type        = string
  default     = "t3.small"
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of existing EC2 key pair for SSH access (set in terraform.tfvars)"
  type        = string

  validation {
    condition     = length(var.key_name) > 0
    error_message = "key_name must not be empty."
  }
}

variable "ssh_cidr" {
  description = "CIDR block allowed for SSH (restrict to your IP in production)"
  type        = string
  default     = "0.0.0.0/0"
}
