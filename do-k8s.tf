provider "digitalocean" {
  token = var.do_token
  version = ">=1.20"
}

##############################

variable "do_token" {
  description = "API token"
  type = string
}

variable "do_ssh_fingerprint" {
  description = "Fingerprint of SSH key"
  type = string
}

variable "do_region" {
  description = "Default DO region"
  type = string
  default = "ams2"
}

variable "do_image" {
  description = "Default DO image"
  type = string
  default = "ubuntu-18-04-x64"
}

variable "do_master_size" {
  description = "Default master size"
  type = string
  default = "s-2vcpu-2gb"
}

variable "do_node_size" {
  description = "Default node size"
  type = string
  default = "s-2vcpu-2gb"
}

##############################

resource "digitalocean_tag" "do_k8s" {
  name = "do_k8s"
}

resource "digitalocean_tag" "do_k8s_master" {
  name = "do_k8s_master"
}

resource "digitalocean_tag" "do_k8s_node" {
  name = "do_k8s_node"
}

resource "digitalocean_vpc" "k8s_vpc" {
  name = "k8s-vpc"
  region = var.do_region
}

##############################

resource "digitalocean_droplet" "master" {
  count = var.master_cnt
  image = var.do_image
  name = "master-${count.index+1}"
  region = var.do_region
  size = var.do_master_size
  vpc_uuid = digitalocean_vpc.k8s_vpc.id
  tags = [digitalocean_tag.do_k8s.id,
          digitalocean_tag.do_k8s_master.id]
  ssh_keys = [var.do_ssh_fingerprint]
  monitoring = true
}

resource "digitalocean_droplet" "node" {
  count = var.node_cnt
  image = var.do_image
  name = "node-${count.index+1}"
  region = var.do_region
  size = var.do_node_size
  vpc_uuid = digitalocean_vpc.k8s_vpc.id
  tags = [digitalocean_tag.do_k8s.id,
          digitalocean_tag.do_k8s_node.id]
  ssh_keys = [var.do_ssh_fingerprint]
  monitoring = true
}

##############################

resource "digitalocean_firewall" "base_fw" {
  name = "k8s-base-fw"
  tags = [digitalocean_tag.do_k8s.id]

  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    source_tags = [digitalocean_tag.do_k8s.id]
    source_addresses = [digitalocean_vpc.k8s_vpc.ip_range]
  }
  inbound_rule {
    protocol = "udp"
    port_range = "1-65535"
    source_tags = [digitalocean_tag.do_k8s.id]
    source_addresses = [digitalocean_vpc.k8s_vpc.ip_range]
  } 
  outbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
  outbound_rule {
    protocol = "udp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
  outbound_rule {
    protocol = "icmp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}

resource "digitalocean_firewall" "node_fw" {
  name = "k8s-node-fw"
  tags = [digitalocean_tag.do_k8s_node.id]

  inbound_rule {
    protocol = "tcp"
    port_range = "30000-32767"
    source_addresses = ["0.0.0.0/0"]
  } 
}

##############################

output "master_ips_public" {
  value = "${zipmap(digitalocean_droplet.master.*.name, digitalocean_droplet.master.*.ipv4_address)}"
}

output "master_ips_private" {
  value = "${zipmap(digitalocean_droplet.master.*.name, digitalocean_droplet.master.*.ipv4_address_private)}"
}

output "node_ips_public" {
  value = "${zipmap(digitalocean_droplet.node.*.name, digitalocean_droplet.node.*.ipv4_address)}"
}

output "node_ips_private" {
  value = "${zipmap(digitalocean_droplet.node.*.name, digitalocean_droplet.node.*.ipv4_address_private)}"
}