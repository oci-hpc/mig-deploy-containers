resource "oci_core_vcn" "simple" {
  count          = local.use_existing_network ? 0 : 1
  cidr_block     = var.vcn_cidr_block
  dns_label      = substr(var.vcn_dns_label, 0, 15)
  compartment_id = var.network_compartment_ocid
  display_name   = var.vcn_display_name

  freeform_tags = map(var.tag_key_name, var.tag_value)
}

#IGW
resource "oci_core_internet_gateway" "simple_internet_gateway" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.simple[count.index].id
  enabled        = "true"
  display_name   = "${var.vcn_display_name}-igw"

  freeform_tags = map(var.tag_key_name, var.tag_value)
}

resource "oci_core_security_list" "public_fss_security_list" {
  count          = local.use_existing_network ? 0 : 1
  vcn_id         = oci_core_vcn.simple[count.index].id
  compartment_id = var.targetCompartment

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      max = "111"
      min = "111"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      max = "2048"
      min = "2050"
    }
  }

  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"
    tcp_options {
      max = "111"
      min = "111"
    }
  }

  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"
    tcp_options {
      max = "2048"
      min = "2048"
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules { 
    protocol = "1"
    source = "0.0.0.0/0"
    icmp_options { 
      type = "3"
      code = "4"
    }
  }
}

#simple subnet
resource "oci_core_subnet" "simple_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  cidr_block                 = var.subnet_cidr_block
  security_list_ids          = [ oci_core_security_list.public_fss_security_list[0].id ]
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.simple[count.index].id
  display_name               = var.subnet_display_name
  dns_label                  = substr(var.subnet_dns_label, 0, 15)
  prohibit_public_ip_on_vnic = ! local.is_public_subnet

  freeform_tags = map(var.tag_key_name, var.tag_value)
}

resource "oci_core_route_table" "simple_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.simple[count.index].id
  display_name   = "${var.subnet_display_name}-rt"

  route_rules {
    network_entity_id = oci_core_internet_gateway.simple_internet_gateway[count.index].id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  freeform_tags = map(var.tag_key_name, var.tag_value)
}

resource "oci_core_route_table_attachment" "route_table_attachment" {
  count          = local.use_existing_network ? 0 : 1
  subnet_id      = oci_core_subnet.simple_subnet[count.index].id
  route_table_id = oci_core_route_table.simple_route_table[count.index].id
}