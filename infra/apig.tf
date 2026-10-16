# ============================================
# APIG - API Gateway
# ============================================

resource "huaweicloud_apig_instance" "main" {
  name                  = "${var.project_name}-apig"
  edition               = "BASIC"
  vpc_id               = huaweicloud_vpc.main.id
  subnet_id            = huaweicloud_vpc_subnet.subnet_a.id
  security_group_id    = huaweicloud_networking_secgroup.fgs_sg.id
}

resource "huaweicloud_apig_group" "main" {
  instance_id = huaweicloud_apig_instance.main.id
  name       = "${var.project_name}-group"
}

resource "huaweicloud_apig_environment" "main" {
  instance_id = huaweicloud_apig_instance.main.id
  name       = "release-v1"
}
