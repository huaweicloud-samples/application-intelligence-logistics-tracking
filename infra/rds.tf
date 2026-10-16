# ============================================
# GaussDB Database (PostgreSQL compatible)
# ============================================

resource "huaweicloud_gaussdb_instance" "main" {
  name              = "${var.project_name}-db"
  flavor           = var.rds_flavor
  vpc_id           = huaweicloud_vpc.main.id
  subnet_id        = huaweicloud_vpc_subnet.subnet_a.id
  security_group_id = huaweicloud_networking_secgroup.rds_sg.id
  
  availability_zone = "cn-north-4a"
  password         = var.db_password

  datastore {
    engine   = "opengauss"
    version = "2.0"
  }
  
  volume {
    type = "ULTRAHIGH"
    size = var.rds_storage
  }

  ha {
    mode             = "main"
    replication_mode = "sync"
  }

  backup_strategy {
    start_time = "01:00-02:00"
    keep_days  = 1
  }
}

resource "huaweicloud_gaussdb_database" "main" {
  instance_id = huaweicloud_gaussdb_instance.main.id
  name       = "company_logistics_db"
}
