variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" { default = "ap-chuncheon-1" } # 또는 ap-seoul-1
variable "compartment_ocid" {}
variable "availability_domain" {} # 예: "ABCD:AP-CHUNCHEON-1-AD-1"
variable "ssh_public_key_path" { default = "~/.ssh/id_rsa.pub" }