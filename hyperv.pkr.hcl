source "hyperv-iso" "win2022" {
  # https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso
  iso_url      = "${var.iso_url}"
  iso_checksum = "none"

  vm_name          = "win2022"
  memory           = 4096
  disk_size        = 61440
  cpus             = 2
  disable_shutdown = true
  switch_name      = "External"

  boot_command         = ["a<enter><wait>a<enter><wait>a<enter><wait>a<enter>"]
  boot_wait            = "1s"
  communicator         = "winrm"
  secondary_iso_images = ["./data/win_2022/secondary.iso"]

  temp_path        = "."
  output_directory = "output-win2022"
  generation       = 2

  # Enable dynamic memory
  enable_dynamic_memory = true

  enable_secure_boot               = false
  enable_mac_spoofing              = false
  enable_virtualization_extensions = false
  enable_tpm                       = false
  keep_registered                  = false
  skip_export                      = true
  shutdown_timeout                 = "30m"
  headless                         = true

  winrm_username = "Administrator"
  winrm_password = "SecretThingToChange!123"
  winrm_timeout  = "4m"
  winrm_use_ssl  = true
  winrm_insecure = true
}

build {
  sources = ["source.hyperv-iso.win2022"]
}