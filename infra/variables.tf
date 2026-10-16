variable "HW_ACCESS_KEY" {
  description = "Huawei Cloud Access Key"
  type        = string
  sensitive  = true
}

variable "HW_SECRET_KEY" {
  description = "Huawei Cloud Secret Key"
  type        = string
  sensitive  = true
}

variable "HW_REGION_NAME" {
  description = "Huawei Cloud Region"
  type        = string
  default    = "cn-north-4"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default    = "logistics-agent"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default    = "10.0.0.0/16"
}

variable "subnet_a_cidr" {
  description = "Subnet A CIDR block"
  type        = string
  default    = "10.0.1.0/24"
}

variable "subnet_b_cidr" {
  description = "Subnet B CIDR block"
  type        = string
  default    = "10.0.2.0/24"
}

variable "rds_flavor" {
  description = "RDS flavor"
  type        = string
  default    = "rds.mysql.s1.small"
}

variable "rds_storage" {
  description = "RDS storage size in GB"
  type        = number
  default    = 20
}

variable "model_api_key" {
  description = "MaaS API Key for model inference"
  type        = string
  sensitive  = true
}

variable "model_endpoint" {
  description = "MaaS model inference endpoint"
  type        = string
  default     = "https://api.modelarts-maas.com"
}

variable "model_id" {
  description = "MaaS model ID"
  type        = string
  default    = "DeepSeek-V4"
}

variable "db_user" {
  description = "RDS database user"
  type        = string
  default    = "root"
}

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive  = true
  default    = "LogisticsAgent2024!"
}
