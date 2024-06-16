source "hyperv-iso" "win2022" {
  boot_command                     = ["a<enter><wait>a<enter><wait>a<enter><wait>a<enter>"]
  boot_wait                        = var.hv_boot_wait
  communicator                     = "winrm"
  cpus                             = var.hv_cpus
  disk_size                        = var.hv_disk_size
  disable_shutdown                 = var.hv_disable_shutdown
  enable_dynamic_memory            = var.hv_enable_dynamic_memory
  enable_mac_spoofing              = var.hv_enable_mac_spoofing
  enable_secure_boot               = var.hv_enable_secure_boot
  enable_virtualization_extensions = var.hv_enable_virtualization_extensions
  enable_tpm                       = var.hv_enable_tpm
  generation                       = var.hv_generation
  guest_additions_mode             = var.hv_guest_additions_mode
  iso_checksum                     = var.hv_iso_checksum
  iso_url                          = "${var.hv_iso_url}"
  memory                           = var.hv_memory
  output_directory                 = var.hv_output_directory
  secondary_iso_images             = var.hv_secondary_iso_images
  shutdown_command                 = "shutdown /s /f /t 0"
  switch_name                      = var.hv_switch_name
  temp_path                        = var.hv_temp_path
  vlan_id                          = var.hv_vlan_id
  vm_name                          = var.hv_vm_name
  winrm_username                   = var.hv_winrm_username
  winrm_password                   = var.hv_winrm_password
  winrm_timeout                    = var.hv_winrm_timeout
  winrm_use_ssl                    = var.hv_winrm_use_ssl
  winrm_insecure                   = var.hv_winrm_insecure

  keep_registered = var.hv_keep_registered
  skip_export     = var.hv_skip_export
  headless        = var.hv_headless
}

build {
  sources = ["source.hyperv-iso.win2022"]
}