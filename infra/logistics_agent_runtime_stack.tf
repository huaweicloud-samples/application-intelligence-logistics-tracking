# ============================================
# Terraform Configuration
# ============================================

terraform {
  required_version = ">= 1.5"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.0"
    }
  }
}

# Provider Configuration
provider "huaweicloud" {
  region     = var.HW_REGION_NAME
  access_key = var.HW_ACCESS_KEY
  secret_key = var.HW_SECRET_KEY
}
