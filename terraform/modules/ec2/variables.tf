variable "vpc_id" {
  description = "VPC ID where the EC2 instance will be launched."
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to resources"
  type        = string
}


variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "allocate_eip" {
  description = "Flag to allocate Elastic IP"
  type        = bool
  default     = true
}


variable "public_subnet_id" {
  description = "Public subnet ID"
  type        = string
}

variable "dockerhub_user" {
  description = "DockerHub username"
  type        = string
}

variable "image_tag" {
  description = "Gandalf image tag"
  type        = string
}

variable "app_private_ip" {
  description = "App static private IP"
  type        = string
}

