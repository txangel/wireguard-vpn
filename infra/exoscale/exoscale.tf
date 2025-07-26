variable "exoscale_api_key" {
  type        = string
  default = "exoscale api key"
}
variable "exoscale_api_secret" {
  type        = string
  default = "exoscale api secret"
}
provider "exoscale" {
  key    = var.exoscale_api_key
  secret = var.exoscale_api_secret
}

locals {
  zone = "ch-gva-2"
}

data "exoscale_template" "ubuntu" {
  zone = local.zone
  name = "Linux Ubuntu 20.04 LTS 64-bit"
}

resource "tls_private_key" "wireguard" {
  algorithm = "ED25519"
}

variable "ssh_keys" {
  type = set(string)
  default = ["wireguard"]
}

resource "exoscale_compute_instance" "ubuntu-wireguard" {
  zone         = local.zone
  name = "ubuntu-wireguard"
  type         = "standard.micro"
  template_id  = data.exoscale_template.ubuntu.id
  disk_size    = 10
  security_group_ids = [exoscale_security_group.vpn.id]
  ssh_keys = var.ssh_keys
  user_data    = <<EOF
#cloud-config
package_upgrade: true
EOF
}


resource "exoscale_security_group" "vpn" {
  name        = "wireguard"
  description = "allow vpn traffic"

}

resource "exoscale_security_group_rule" "vpn_shh" {
  security_group_id = exoscale_security_group.vpn.id
  type = "INGRESS"
  start_port = 22
  end_port = 22
  protocol = "TCP"
  cidr = "0.0.0.0/0"
}

resource "exoscale_security_group_rule" "vpn_udp" {
  security_group_id = exoscale_security_group.vpn.id
  type = "INGRESS"
  start_port = 51820
  end_port = 51820
  protocol = "UDP"
  cidr = "0.0.0.0/0"
}

resource "local_file" "hosts" {
  filename = "../../hosts"
  content = "[vpn]\n${exoscale_compute_instance.ubuntu-wireguard.public_ip_address} ansible_user=root"
}
