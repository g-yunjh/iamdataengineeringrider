terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.0.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# 1. VCN (가상 네트워크) 생성
resource "oci_core_vcn" "bike_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = "10.0.0.0/16"
  display_name   = "seoul_bike_vcn"
}

# 2. Internet Gateway (인터넷 연결)
resource "oci_core_internet_gateway" "bike_ig" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bike_vcn.id
  display_name   = "bike_internet_gateway"
}

# 3. Route Table
resource "oci_core_route_table" "bike_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bike_vcn.id
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.bike_ig.id
  }
}

# 4. Security List (방화벽 규칙)
resource "oci_core_security_list" "bike_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.bike_vcn.id
  display_name   = "bike_security_list"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 8080
      max = 8080
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 8081
      max = 8081
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 9001
      max = 9001
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 8501
      max = 8501
    }
  }
}

# 5. Subnet 생성
resource "oci_core_subnet" "bike_subnet" {
  cidr_block        = "10.0.1.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.bike_vcn.id
  route_table_id    = oci_core_route_table.bike_rt.id
  security_list_ids = [oci_core_security_list.bike_sl.id]
  display_name      = "bike_subnet"
}

# 6. Ubuntu ARM 이미지 찾기 (자동)
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# 7. Compute Instance 생성 (VM) 🌟 핵심
resource "oci_core_instance" "bike_server" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  shape               = "VM.Standard.A1.Flex"
  display_name        = "seoul_bike_platform"

  shape_config {
    ocpus         = 4  # 🌟 무료 티어 최대치
    memory_in_gbs = 24 # 🌟 무료 티어 최대치
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.bike_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_arm.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
}

# 출력: 생성된 VM의 공인 IP
output "public_ip" {
  value = oci_core_instance.bike_server.public_ip
}