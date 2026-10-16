# ============================================
# Network - VPC, Subnets, NAT Gateway, Security Groups
# ============================================

# VPC
resource "huaweicloud_vpc" "main" {
  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr
}

# Subnets
resource "huaweicloud_vpc_subnet" "subnet_a" {
  name       = "${var.project_name}-subnet-a"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = var.subnet_a_cidr
  gateway_ip = cidrhost(var.subnet_a_cidr, 1)
}

resource "huaweicloud_vpc_subnet" "subnet_b" {
  name       = "${var.project_name}-subnet-b"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = var.subnet_b_cidr
  gateway_ip = cidrhost(var.subnet_b_cidr, 1)
}

# NAT Gateway
resource "huaweicloud_vpc_eip" "nat_eip" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name       = "${var.project_name}-nat-bandwidth"
    size       = 10
    share_type = "PER"
  }
}

resource "huaweicloud_nat_gateway" "main" {
  name     = "${var.project_name}-nat"
  vpc_id   = huaweicloud_vpc.main.id
  subnet_id = huaweicloud_vpc_subnet.subnet_a.id
  spec     = "1"
}

resource "huaweicloud_nat_snat_rule" "main" {
  nat_gateway_id = huaweicloud_nat_gateway.main.id
  floating_ip_id = huaweicloud_vpc_eip.nat_eip.id
  subnet_id     = huaweicloud_vpc_subnet.subnet_a.id
}

# Security Groups
resource "huaweicloud_networking_secgroup" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
}

resource "huaweicloud_networking_secgroup_rule" "rds_ingress" {
  security_group_id = huaweicloud_networking_secgroup.rds_sg.id
  direction       = "ingress"
  ethertype       = "IPv4"
  protocol        = "tcp"
  port_range_min  = 5432
  port_range_max  = 5432
  remote_ip_prefix = var.subnet_a_cidr
}

resource "huaweicloud_networking_secgroup_rule" "rds_ingress_b" {
  security_group_id = huaweicloud_networking_secgroup.rds_sg.id
  direction       = "ingress"
  ethertype       = "IPv4"
  protocol        = "tcp"
  port_range_min  = 5432
  port_range_max  = 5432
  remote_ip_prefix = var.subnet_b_cidr
}

resource "huaweicloud_networking_secgroup" "fgs_sg" {
  name        = "${var.project_name}-fgs-sg"
  description = "Security group for FunctionGraph"
}

resource "huaweicloud_networking_secgroup_rule" "fgs_ingress" {
  security_group_id = huaweicloud_networking_secgroup.fgs_sg.id
  direction       = "ingress"
  ethertype       = "IPv4"
  protocol        = "tcp"
  port_range_min  = 80
  port_range_max  = 443
  remote_ip_prefix = "0.0.0.0/0"
}
