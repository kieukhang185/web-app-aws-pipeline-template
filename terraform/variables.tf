# Networking vars
variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy resources in"
}

variable "app_name" {
  type        = string
  default     = "web-app-aws-pipeline"
  description = "Name of the application"
}

variable "project_name" {
  type        = string
  default     = "vtd-devops-khangkieu"
  description = "Name of the project"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment (e.g., dev, staging, prod)"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR for the VPC"
}

variable "container_port" {
  type        = number
  default     = 8000
  description = "App container port (must match task definition & target group)"
}

variable "github_repo" {
  type        = string
  default     = "kieukhang185/web-app-aws-pipeline-template"
  description = "GitHub repository name"
} # e.g. "org/repo"
variable "github_branch" {
  type        = string
  default     = "main"
  description = "GitHub branch name"
} # e.g. "main"