provider "alicloud" {
  #   access_key = "${var.access_key}"
  #   secret_key = "${var.secret_key}"
  region = "cn-hongkong"
}

######## Security group
resource "alicloud_security_group" "group" {
  name        = "sg_adb_pg"
  description = "Security group for AnalyticDB for PostgreSQL"
  vpc_id      = alicloud_vpc.default.id
}

resource "alicloud_security_group_rule" "allow_http_80" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_https_443" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "443/443"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_ssh_22" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_rdp_3389" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "3389/3389"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_all_icmp" {
  type              = "ingress"
  ip_protocol       = "icmp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

######## ECS
resource "alicloud_instance" "instance" {
  security_groups = alicloud_security_group.group.*.id

  instance_type           = "ecs.g5.2xlarge" # 8core 32GB
  system_disk_category    = "cloud_essd"
  system_disk_name        = "adbpg_tpch_system_disk"
  system_disk_size        = 100
  system_disk_description = "adbpg_tpch_system_disk"
  image_id                = "centos_8_3_x64_20G_alibase_20210521.vhd"
  instance_name           = "adbpg_tpch"
  password                = "N1cetest" ## Please change accordingly
  instance_charge_type    = "PostPaid"
  vswitch_id              = alicloud_vswitch.default.id
  data_disks { ## ESSD PL3 2TB data disk
    name              = "disk2"
    size              = 200
    category          = "cloud_essd"
    performance_level = "PL1"
    description       = "disk2"
  }
}

######## EIP bind to setup ECS accessing from internet
resource "alicloud_eip" "setup_ecs_access" {
  bandwidth            = "5"
  internet_charge_type = "PayByBandwidth"
}

resource "alicloud_eip_association" "eip_ecs" {
  allocation_id = alicloud_eip.setup_ecs_access.id
  instance_id   = alicloud_instance.instance.id
}

variable "analyticdb_postgresql_name" {
  default = "analyticdb_postgresql"
}

variable "creation" {
  default = "Gpdb"
}

data "alicloud_zones" "default" {
  available_resource_creation = var.creation
}

######## VPC
resource "alicloud_vpc" "default" {
  vpc_name   = "vpc-adb-postgresql"
  cidr_block = "172.16.0.0/16"
}

resource "alicloud_vswitch" "default" {
  vpc_id       = alicloud_vpc.default.id
  cidr_block   = "172.16.0.0/24"
  zone_id      = data.alicloud_zones.default.zones[0].id
  vswitch_name = "vsw-adb-postgresql"
}

######## AnalyticDB for PostgreSQL
resource "alicloud_gpdb_elastic_instance" "adb_pg_instance" {
  engine                  = "gpdb"
  engine_version          = "6.0"
  seg_storage_type        = "cloud_essd"
  seg_node_num            = 8
  storage_size            = 200
  instance_spec           = "2C16G"
  db_instance_description = "Created by terraform"
  instance_network_type   = "VPC"
  payment_type            = "PayAsYouGo"
  vswitch_id              = alicloud_vswitch.default.id
  security_ip_list        = ["0.0.0.0/0"]
}

######## Output 

output "eip_ecs" {
  value = alicloud_eip.setup_ecs_access.ip_address
}

output "adb_pg_id" {
  value = alicloud_gpdb_elastic_instance.adb_pg_instance.id
}

output "adb_pg_connection_string" {
  value = alicloud_gpdb_elastic_instance.adb_pg_instance.connection_string
}

output "adb_pg_status" {
  value = alicloud_gpdb_elastic_instance.adb_pg_instance.status
}
