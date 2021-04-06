resource "tls_private_key" "public_private_key_pair" {
  algorithm   = "RSA"
}

resource "oci_core_instance" "simple-vm" {
  availability_domain = local.availability_domain
  compartment_id      = var.compute_compartment_ocid
  display_name        = var.vm_display_name
  shape               = var.vm_compute_shape

  dynamic "shape_config" {
    for_each = local.is_flex_shape
      content {
        ocpus = shape_config.value
      }
  }


  create_vnic_details {
    subnet_id              = local.use_existing_network ? var.subnet_id : oci_core_subnet.simple_subnet[0].id
    display_name           = var.subnet_display_name
    assign_public_ip       = local.is_public_subnet
    hostname_label         = var.hostname_label
    skip_source_dest_check = false
    nsg_ids                = [oci_core_network_security_group.simple_nsg.id]
  }

  source_details {
    source_type = "image"
    source_id   = var.custom_image_id
    #use a marketplace image or custom image:
    #source_id   = local.compute_image_id
  }

  lifecycle {
    ignore_changes = [
      source_details[0].source_id
    ]
  }
  
  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}\n${tls_private_key.public_private_key_pair.public_key_openssh}"
    user_data           = base64encode(file("./scripts/example.sh"))
  }

  freeform_tags = map(var.tag_key_name, var.tag_value)
}

resource "time_sleep" "wait" {
  depends_on = [oci_core_instance.simple-vm]

  create_duration = "240s"
}
  
resource "null_resource" "remote-exec" {
  depends_on = [time_sleep.wait]

  provisioner "file" {
    connection {
      type        = "ssh"
      host        = oci_core_instance.simple-vm.public_ip
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }

    source      = "playbooks"
    destination = "~"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      host        = oci_core_instance.simple-vm.public_ip
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }

    content     = yamlencode(
      { 
        "registry_url"      : var.registry_url, 
        "registry_username" : var.registry_username, 
        "registry_password" : var.registry_password,
        "docker_image_name" : var.docker_image_name 
      }
    )
    destination = "~/playbooks/roles/nvidia-docker/vars/main.yml"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      host        = oci_core_instance.simple-vm.public_ip
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }

    content     = yamlencode(
      { 
        "mig_number_devices" : var.mig_number_devices
      }
    )
    destination = "~/playbooks/roles/enable-mig/vars/main.yml"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      host        = oci_core_instance.simple-vm.public_ip
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }

    content      = yamlencode(
      {
        "nfs_target_path" : var.nfs_target_path,
        "nfs_source_IP"   : var.create_fss ? oci_file_storage_mount_target.FSSMountTarget[0].ip_address : var.nfs_source_IP
        "nfs_export_path" : var.nfs_export_path
      }
    )
    destination = "~/playbooks/roles/nfs-client/vars/main.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y htop"
    ]
    
    connection {
      type        = "ssh"
      host        = oci_core_instance.simple-vm.public_ip
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  
    
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = oci_core_instance.simple-vm.public_ip
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  
    inline = [
      "sudo yum install -y ansible", 
      "ansible-galaxy collection install community.docker",
      "sudo yum install -y python-pip",
      "pip install docker --user",
      "ansible-playbook ~/playbooks/site.yml"
    ]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = oci_core_instance.simple-vm.public_ip
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  
    inline = [
      "export DOCKER_IMAGE_NAME=${var.docker_image_name}",
      "export DOCKER_RUN_OPTIONS=${var.docker_run_options}",
      "export NFS_EXPORT_PATH=${var.nfs_export_path}",
      "sudo sh ~/playbooks/save-mig-dev.sh",
      "sudo sh ~/playbooks/list-tokens.sh",
      "echo Done!"
    ]
  }
}