# variables.tf

variable "cluster_role_arn" {
  description = "The ARN of the IAM role used by the EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "The ARN of the IAM role used by the EKS worker nodes"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to be used by the EKS cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC to be used by the EKS cluster"
  type        = string
}

variable "assume_role_arn" {
  description = "arn of the assume role"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "arn of kms key"
  type        = string
  default     = ""
}
variable "ami_id" {
  description = "ami id for node workers"
  type        = string
  default     = ""
}
variable "cluster_endpoint_public_access" {
  description = "endpoint access"
  type        = bool
  default     = true
}
variable "cluster_endpoint_private_access" {
  description = "endpoint access"
  type        = bool
  default     = false
}
variable "eks_cluster_version" {
  description = "eks version"
  type        = string
}
variable "eks_node_group_disk_size" {
  description = "disk size"
  type        = number
}
variable "eks_node_group_desired_size" {
  description = "number of nodes"
  type        = number
}
variable "eks_node_group_min_size" {
  description = "minimum number of nodes"
  type        = number
}
variable "eks_node_group_max_size" {
  description = "maximum number of nodes"
  type        = number
}
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}