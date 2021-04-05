resource "oci_file_storage_file_system" "FSS" {
  count                       = var.create_ffs ? 1 : 0
  availability_domain         = var.fss_ad
  compartment_id              = var.fss_compartment
  display_name                = "${var.fss_name}-fss"  
}

resource "oci_file_storage_mount_target" "FSSMountTarget" {
  depends_on = [
    oci_core_subnet.simple_subnet
  ]
  count               = var.create_ffs ? 1 : 0
  availability_domain = var.fss_ad 
  compartment_id      = var.fss_compartment
  subnet_id           = oci_core_subnet.simple_subnet[0].id
  display_name        = "${var.fss_name}-mt"  
  hostname_label      = "fileserver"
}

resource "oci_file_storage_export" "FSSExport" {
  count          = var.create_ffs ? 1 : 0
  export_set_id  = oci_file_storage_mount_target.FSSMountTarget.0.export_set_id
  file_system_id = oci_file_storage_file_system.FSS.0.id
  path           = var.nfs_export_path
  export_options {
    source = var.vcn_cidr_block
    access = "READ_WRITE"
    identity_squash = "NONE"
  }
}