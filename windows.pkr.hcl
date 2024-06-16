source "hyperv-iso" "win2022" {
  boot_command                     = ["a<enter><wait>a<enter><wait>a<enter><wait>a<enter>"]
  boot_wait                        = "1s"
  communicator                     = "winrm"
  cpus                             = 2
  disk_size                        = 61440
  enable_dynamic_memory            = true
  enable_mac_spoofing              = true
  enable_secure_boot               = true
  enable_virtualization_extensions = false
  enable_tpm                       = false
  generation                       = 2
  guest_additions_mode             = "disable"
  iso_checksum                     = "none"
  iso_url                          = "${var.iso_url}"
  # https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso
  memory               = 4096
  output_directory     = "output-win2022"
  secondary_iso_images = ["./data/win_2022/secondary.iso"]
  shutdown_command     = "shutdown /s /f /t 0"
  switch_name          = "External"
  temp_path            = "."
  vlan_id              = ""
  vm_name              = "win2022"
  winrm_username       = "Administrator"
  winrm_password       = "SecretThingToChange!123"
  winrm_timeout        = "4m"
  winrm_use_ssl        = true
  winrm_insecure       = true

  keep_registered = false
  skip_export     = true
  headless        = false
}

build {
  sources = ["source.hyperv-iso.win2022"]
}