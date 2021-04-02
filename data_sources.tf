data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = var.availability_domain_number
}

data "oci_core_images" "autonomous_ol7" {
  compartment_id   = var.compute_compartment_ocid
  operating_system = "Oracle Autonomous Linux"
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"
  state            = "AVAILABLE"

  # filter restricts to OL 7
  filter {
    name   = "operating_system_version"
    values = ["7\\.[0-9]"]
    regex  = true
  }
}

data "oci_core_images" "ol7_gpu" {
  compartment_id   = var.compute_compartment_ocid
  operating_system = "Oracle Linux"
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"
  state            = "AVAILABLE"

  # filter restricts to OL 7
  filter {
    name   = "display_name"
    #values = ["GPU"]
    values = ["Oracle"]
    regex  = true
  }
}
