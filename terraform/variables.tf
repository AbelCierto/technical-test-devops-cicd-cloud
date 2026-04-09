variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "todo-app"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_1" {
  description = "AZ 1"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "AZ 2"
  type        = string
  default     = "us-east-1b"
}

variable "container_port" {
  description = "Application container port"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "Fargate CPU"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate Memory"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired task count"
  type        = number
  default     = 1
}

variable "container_image" {
  description = "Initial container image. Later GitHub Actions can update this."
  type        = string
  default     = "public.ecr.aws/docker/library/node:18-alpine"
}

variable "github_repo" {
  description = "GitHub repository in the format owner/repo for OIDC trust"
  type        = string
  default     = "your-user/technical-test-devops-cicd-cloud"
}