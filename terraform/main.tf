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

# AD 자동 검색
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# 1. VCN
resource "oci_core_vcn" "bike_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = "10.0.0.0/16"
  display_name   = "seoul_bike_vcn_amd"
}

# 2. Internet Gateway
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

# 4. Security List
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

  # Streamlit (8501) - 혹시 몰라 열어둠
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 8501
      max = 8501
    }
  }
}

# 5. Subnet
resource "oci_core_subnet" "bike_subnet" {
  cidr_block        = "10.0.1.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.bike_vcn.id
  route_table_id    = oci_core_route_table.bike_rt.id
  security_list_ids = [oci_core_security_list.bike_sl.id]
  display_name      = "bike_subnet_amd"
}

# 6. Image (AMD Ubuntu)
data "oci_core_images" "ubuntu_amd" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# 7. Instance (AMD 1GB)
resource "oci_core_instance" "bike_server" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "seoul_bike_platform_amd"

  create_vnic_details {
    subnet_id        = oci_core_subnet.bike_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_amd.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
}

output "public_ip" {
  value = oci_core_instance.bike_server.public_ip
}