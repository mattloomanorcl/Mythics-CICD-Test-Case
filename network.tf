data "oci_core_services" "all" {}

locals {
  all_services = one([for service in data.oci_core_services.all.services : service if startswith(service.name, "All ")])
}

resource "oci_core_vcn" "function" {
  count          = var.network_choice == "Define" ? 1 : 0
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "${var.name_prefix}-vcn"
  dns_label      = "funcvcn"
}

resource "oci_core_service_gateway" "function" {
  count          = var.network_choice == "Define" ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.function[0].id
  display_name   = "${var.name_prefix}-service-gateway"
  services {
    service_id = local.all_services.id
  }
}

resource "oci_core_route_table" "function" {
  count          = var.network_choice == "Define" ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.function[0].id
  display_name   = "${var.name_prefix}-private-routes"
  route_rules {
    destination       = local.all_services.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.function[0].id
  }
}

resource "oci_core_security_list" "function" {
  count          = var.network_choice == "Define" ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.function[0].id
  display_name   = "${var.name_prefix}-function-egress"
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
}

resource "oci_core_subnet" "function" {
  count                      = var.network_choice == "Define" ? 1 : 0
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.function[0].id
  cidr_block                 = var.subnet_cidr
  display_name               = "${var.name_prefix}-function-subnet"
  dns_label                  = "functions"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.function[0].id
  security_list_ids          = [oci_core_security_list.function[0].id]
}

locals {
  subnet_id = var.network_choice == "Select" ? var.existing_subnet_ocid : oci_core_subnet.function[0].id
}
