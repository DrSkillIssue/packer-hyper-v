variable "hv_vm_name" {
  type        = string
  description = <<-EOT
    This is the name of the new virtual machine, without the file extension. 
    
    By default this is "packer-BUILDNAME", where "BUILDNAME" is the name of the build.
  EOT
}

variable "hv_switch_name" {
  type        = string
  description = <<-EOT
    The name of the switch to connect the virtual machine to. 
    
    By default, leaving this value unset will cause Packer to try and determine the switch to use by looking for an external switch that is up and running.
  EOT
}

variable "hv_iso_url" {
  type        = string
  description = "A URL to the ISO containing the installation image or virtual hard drive (VHD or VHDX) file to clone."
  # default = "https://software-download.microsoft.com/download/sg/20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
}

variable "hv_iso_checksum" {
  type        = string
  description = <<-EOT
    "The checksum for the ISO file or virtual hard drive file.

    The type of the checksum is specified within the checksum field as a prefix, ex: "md5:{$checksum}".

    The type of the checksum can also be omitted and Packer will try to infer it based on string length. 

    Valid values are:
      - "none", 
      - "{$checksum}", 
      - "md5:{$checksum}", 
      - "sha1:{$checksum}", 
      - "sha256:{$checksum}", 
      - "sha512:{$checksum}",
      - "file:{$path}". 
      
    Here is a list of valid checksum values:
      - "md5:090992ba9fd140077b0661cb75f7ce13"
      - "sha256:{$checksum}"
      - "sha512:{$checksum}",
      - "ed363350696a726b7932db864dda019bd2017365c9e299627830f06954643f93",
      - "file:http://releases.ubuntu.com/20.04/SHA256SUMS",
      - "file://./local/path/file.sum"
      - "file:./local/path/file.sum"
    EOT
  # default = "sha256:4f1457c4fe14ce48c9b2324924f33ca4f0470475e6da851b39ccbf98f44e7852"
}

variable "hv_disk_size" {
  type        = number
  description = "The size, in megabytes, of the hard disk to create for the VM. By default, this is 40 GB."
  default     = 51200
}

variable "hv_memory" {
  type        = number
  description = "The amount, in megabytes, of RAM to assign to the VM. By default, this is 1 GB."
  default     = 4096
}

variable "hv_enable_dynamic_memory" {
  type        = bool
  description = "If true enable dynamic memory for the virtual machine. This defaults to false."
  default     = false
}

variable "hv_cpus" {
  type        = number
  description = "The number of CPUs the virtual machine should use. If this isn't specified, the default is 1 CPU."
  default     = 1
}

variable "hv_switch_vlan_id" {
  type        = string
  description = <<-EOT
    This is the VLAN of the virtual switch's network card. 
    
    By default none is set. 
    
    If none is set then a VLAN is not set on the switch's network card. 
    
    If this value is set it should match the VLAN specified in by vlan_id.
  EOT

  default = null
}

variable "hv_vlan_id" {
  type        = string
  description = <<-EOT
    This is the VLAN of the virtual machine's network card for the new virtual machine. 
    
    By default none is set. 
    
    If none is set then VLANs are not set on the virtual machine's network card.
  EOT

  default = null
}

variable "hv_generation" {
  type        = number
  description = <<-EOT
    The Hyper-V generation for the virtual machine. By default, this is 1. Generation 2 Hyper-V virtual machines do not support floppy drives. 
    
    In this scenario use secondary_iso_images instead. Hard drives and DVD drives will also be SCSI and not IDE.
  EOT

  default = 2
}

variable "hv_enable_secure_boot" {
  type        = bool
  description = "If true enable secure boot for the virtual machine. This defaults to false. See secure_boot_template below for additional settings."
  default     = false
}

variable "hv_secure_boot_template" {
  type        = string
  description = <<-EOT
    The secure boot template to be configured. 
    
    Valid values are:
      - "MicrosoftWindows" (Windows) 
      - "MicrosoftUEFICertificateAuthority" (Linux). 
      
    This only takes effect if enable_secure_boot is set to "true". 
    
    This defaults to "MicrosoftWindows".
  EOT

  default = "MicrosoftWindows"
}

variable "hv_enable_virtualization_extensions" {
  type        = bool
  description = <<-EOT
     If true enable virtualization extensions for the virtual machine. 
     
     This defaults to false. 
     
     For nested virtualization you need to enable MAC spoofing, disable dynamic memory and have at least 4GB of RAM assigned to the virtual machine.
  EOT

  default = false
}

variable "hv_enable_mac_spoofing" {
  type        = bool
  description = "If true enable MAC address spoofing for the virtual machine. This defaults to false."
  default     = false
}

variable "hv_enable_tpm" {
  type        = bool
  description = "If true enable a virtual TPM for the virtual machine. This defaults to false."
  default     = false
}

variable "hv_iso_urls" {
  type        = list(string)
  description = <<-EOT
    Multiple URLs for the ISO to download. Packer will try these in order. 
    
    If anything goes wrong attempting to download or while downloading a single URL, it will move on to the next. 
    
    All URLs must point to the same file (same checksum). By default this is empty and iso_url is used. 
    
    Only one of iso_url or iso_urls can be specified.
  EOT

  default = null
}

variable "hv_secondary_iso_images" {
  type        = list(string)
  description = <<-EOT
    A list of ISO paths to attach to a VM when it is booted. 

    This is most useful for unattended Windows installs, which look for an Autounattend.xml file on removable media. 

    By default, no secondary ISO will be attached.
  EOT

  default = null
}

variable "hv_iso_target_path" {
  type        = string
  description = <<-EOT
    The path where the iso should be saved after download. 
    By default will go in the packer cache, with a hash of the original filename and checksum as its name.
  EOT

  default = null
}

variable "hv_iso_target_extension" {
  type        = string
  description = "The extension of the iso file after download. This defaults to iso."
  default     = "iso"
}

variable "hv_output_directory" {
  type        = string
  description = <<-EOT
    This setting specifies the directory that artifacts from the build, such as the virtual machine files and disks, will be output to. 
    
    The path to the directory may be relative or absolute.
     If relative, the path is relative to the working directory packer is executed from. 
     This directory must not exist or, if created, must be empty prior to running the builder. 
     
     By default this is "output-BUILDNAME" where "BUILDNAME" is the name of the build.
  EOT

  default = null
}

variable "hv_disable_shutdown" {
  type        = bool
  description = <<-EOT
    Packer normally halts the virtual machine after all provisioners have run when no shutdown_command is defined. 
    
    If this is set to true, Packer will not halt the virtual machine but will assume that the VM will shut itself down when it's done, 
    via the preseed.cfg or your final provisioner. 
    
    Packer will wait for a default of 5 minutes until the virtual machine is shutdown. The timeout can be changed using the shutdown_timeout option.
  EOT

  default = false
}

variable "hv_use_legacy_network_adapter" {
  type        = bool
  description = <<-EOT
    If true use a legacy network adapter as the NIC. 

    This defaults to false. 

    A legacy network adapter is fully emulated NIC, and is thus supported by various exotic operating systems, 
    but this emulation requires additional overhead and should only be used if absolutely necessary.
  EOT

  default = false
}

variable "hv_differencing_disk" {
  type        = bool
  description = <<-EOT
     If true enables differencing disks. 
     
     Only the changes will be written to the new disk. 
     
     This is especially useful if your source is a VHD/VHDX. 
     
     This defaults to false.
  EOT

  default = false
}

variable "hv_use_fixed_vhd_format" {
  type        = bool
  description = <<-EOT
     If true, creates the boot disk on the virtual machine as a fixed VHD format disk. 
     
     The default is false, which creates a dynamic VHDX format disk. 
     
     This option requires setting generation to 1, skip_compaction to true, and differencing_disk to false. 
     
     Additionally, any value entered for disk_block_size will be ignored. 
     
     The most likely use case for this option is outputing a disk that is in the format required for upload to Azure.
  EOT

  default = false
}

variable "hv_disk_block_size" {
  type        = number
  description = <<-EOT
     The block size of the VHD to be created. 
     
     Recommended disk block size for Linux hyper-v guests is 1 MiB. 
     
     This defaults to "32" MiB.
  EOT

  default = 32
}

variable "hv_disk_additional_size" {
  type        = list(number)
  description = <<-EOT
    The size or sizes of any additional hard disks for the VM in megabytes. 
    
    If this is not specified then the VM will only contain a primary hard disk. 
    
    Additional drives will be attached to the SCSI interface only. 
    
    The builder uses expandable rather than fixed-size virtual hard disks, so the actual file representing the disk will not use the full size unless it is full.
  EOT

  default = null
}

variable "hv_guest_additions_mode" {
  type        = string
  description = <<-EOT
    If set to attach then attach and mount the ISO image specified in guest_additions_path. 
    
    If set to none then guest additions are not attached and mounted; 
    
    This is the default.
  EOT

  default = "disable"
}

variable "hv_guest_additions_path" {
  type        = string
  description = "The path to the ISO image for guest additions."
  default     = null
}

variable "hv_mac_address" {
  type        = string
  description = <<-EOT
    This allows a specific MAC address to be used on the default virtual network card. 
    
    The MAC address must be a string with no delimiters, for example "0000deadbeef".
  EOT

  default = null
}

variable "hv_keep_registered" {
  type        = bool
  description = <<-EOT
    If "true", Packer will not delete the VM from The Hyper-V manager. 
    
    The resulting VM will be housed in a randomly generated folder under %TEMP% by default. 
    
    You can set the temp_path variable to change the location of the folder.
  EOT

  default = false
}

variable "hv_temp_path" {
  type        = string
  description = <<-EOT
    The location under which Packer will create a directory to house all the VM files and folders during the build. 
    
    By default %TEMP% is used which, for most systems, will evaluate to %USERPROFILE%/AppData/Local/Temp.

    The build directory housed under temp_path will have a name similar to packerhv1234567.
    
    The seven digit number at the end of the name is automatically generated by Packer to ensure the directory name is unique.
  EOT

  default = null
}

variable "hv_configuration_version" {
  type        = string
  description = "This allows you to set the vm version when calling New-VM to generate the vm."
  default     = null
}

variable "hv_skip_compaction" {
  type        = bool
  description = "If true skip compacting the hard disk for the virtual machine when exporting. This defaults to false."
  default     = false
}

variable "hv_skip_export" {
  type        = bool
  description = <<-EOT
    If true Packer will skip the export of the VM. 
    
    If you are interested only in the VHD/VHDX files, you can enable this option. 
    
    The resulting VHD/VHDX file will be output to <output_directory>/Virtual Hard Disks. 
    
    By default this option is false and Packer will export the VM to output_directory.
  EOT

  default = false
}

variable "hv_headless" {
  type        = bool
  description = <<-EOT
    Packer defaults to building Hyper-V virtual machines by launching a GUI that shows the console of the machine being built. 
    
    When this value is set to true, the machine will start without a console.
  EOT

  default = false
}

variable "hv_first_boot_device" {
  type        = string
  description = <<-EOT
    When configured, determines the device or device type that is given preferential treatment when choosing a boot device.

    For Generation 1:
      - IDE
      - CD or DVD
      - Floppy
      - NET
    
    For Generation 2:
      - IDE:x:y
      - SCSI:x:y
      - CD or DVD
      - NET
  EOT

  default = null
}

variable "hv_boot_order" {
  type        = string
  description = <<-EOT
    When configured, the boot order determines the order of the devices from which to boot.

    The device name must be in the form of SCSI:x:y, for example, to boot from the first scsi device use SCSI:0:0.

    NB You should also set first_boot_device (e.g. DVD).

    NB Although the VM will have this initial boot order, the OS can change it, for example, 
      Ubuntu 18.04 will modify the boot order to include itself as the first boot option.

    NB This only works for Generation 2 machines.
  EOT

  default = null
}

# SHUTDOWN CONFIGURATION REFERENCE
variable "hv_shutdown_command" {
  type        = string
  description = <<-EOT
    The command to use to gracefully shut down the machine once all provisioning is complete. 
    
    By default this is an empty string, which tells Packer to just forcefully shut down the machine. 
    
    This setting can be safely omitted if for example, a shutdown command to gracefully halt the machine is configured inside a provisioning script. 
    
    If one or more scripts require a reboot it is suggested to leave this blank (since reboots may fail) 
      and instead specify the final shutdown command in your last script.

  EOT

  default = null
}

variable "hv_shutdown_timeout" {
  type        = string
  description = <<-EOT
    The amount of time to wait after executing the shutdown_command for the virtual machine to actually shut down. 
    
    If the machine doesn't shut down in this time it is considered an error. 
    
    By default, the time out is "5m" (five minutes).
  EOT

  default = "5m"
}


# CD CONFIGURATION REFERENCE
variable "hv_cd_files" {
  type        = list(string)
  description = <<-EOT
    A list of files to place onto a CD that is attached when the VM is booted. 
    
    This can include either files or directories; any directories will be copied onto the CD recursively, 
      preserving directory structure hierarchy. 
      
    Symlinks will have the link's target copied into the directory tree on the CD where the symlink was. 
      
    File globbing is allowed.

    Usage example (JSON):
      "cd_files": ["./somedirectory/meta-data", "./somedirectory/user-data"],
      "cd_label": "cidata",

    Usage example (HCL):
      cd_files = ["./somedirectory/meta-data", "./somedirectory/user-data"]
      cd_label = "cidata"

    The above will create a CD with two files, user-data and meta-data in the CD root. 
    
    This specific example is how you would create a CD that can be used for an Ubuntu 20.04 autoinstall.

    Since globbing is also supported,
      cd_files = ["./somedirectory/*"]
      cd_label = "cidata"

    Would also be an acceptable way to define the above cd. 
    
    The difference between providing the directory with or without the glob is whether the directory itself or its contents will be at the CD root.

    Use of this option assumes that you have a command line tool installed that can handle the iso creation. 
    
    Packer will use one of the following tools:
      - xorriso
      - mkisofs (Linux)
      - hdiutil (macOS)
      - oscdimg (Windows)
  EOT

  default = null
}

variable "hv_cd_content" {
  type        = map(string)
  description = <<-EOT
    Key/Values to add to the CD. The keys represent the paths, and the values contents. 
    
    It can be used alongside cd_files, which is useful to add large files without loading them into memory. 
    
    If any paths are specified by both, the contents in cd_content will take precedence.

    Usage example (HCL):
      cd_files = ["vendor-data"]
      cd_content = {
        "meta-data" = jsonencode(local.instance_data)
        "user-data" = templatefile("user-data", { packages = ["nginx"] })
      }
      cd_label = "cidata"
  EOT

  default = null
}

variable "hv_cd_label" {
  type        = string
  description = "CD Label"
  default     = null
}


# COMMUNICATOR CONFIGURATION REFERENCE
variable "hv_communicator" {
  type        = string
  description = <<-EOT
    The communicator to use to communicate with the VM. 
    
    By default, this is "winrm". 
    
    The available options are:
      - "none"
      - "ssh"
      - "winrm"

    In addition to the above, some builders have custom communicators they can use. 
    
    For example, the Docker builder has a "docker" communicator that uses docker exec and docker cp to execute scripts and copy files.
  EOT

  default = "winrm"
}

variable "hv_pause_before_connecting" {
  type        = string
  description = <<-EOT
    We recommend that you enable SSH or WinRM as the very last step in your guest's bootstrap script, 
      but sometimes you may have a race condition where you need Packer to wait before attempting to connect to your guest.

    If you end up in this situation, you can use the template option pause_before_connecting. 
    
    By default, there is no pause. 
    
    For example if you set pause_before_connecting to 10m Packer will check whether it can connect, as normal. 
    
    But once a connection attempt is successful, it will disconnect and then wait 10 minutes before connecting to the guest and beginning provisioning.
  EOT

  default = null
}

# OPTIONAL WINRM FIELDS
variable "hv_winrm_username" {
  type        = string
  description = "The username to use to connect to WinRM."
  default     = "Administrator"
}

variable "hv_winrm_password" {
  type        = string
  sensitive   = true
  description = "The password to use to connect to WinRM."
  default     = "SecretThingToChange!123"
}

variable "hv_winrm_host" {
  type        = string
  description = <<-EOT
    The address for WinRM to connect to.

    NOTE: If using an Amazon EBS builder, you can specify the interface WinRM connects to via ssh_interface.

    ssh_interface documentation: https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/builder/ebs#ssh_interface
  EOT

  default = null
}

variable "hv_winrm_no_proxy" {
  type        = bool
  description = <<-EOT
    Setting this to true adds the remote host:port to the NO_PROXY environment variable. 
    
    This has the effect of bypassing any configured proxies when connecting to the remote host. 
    
    Default to false.
  EOT

  default = false
}

variable "hv_winrm_port" {
  type        = number
  description = <<-EOT
    The WinRM port to connect to. 
    
    This defaults to 5985 for plain unencrypted connection and 5986 for SSL when winrm_use_ssl is set to true.
  EOT

  default = 5986
}

variable "hv_winrm_timeout" {
  type        = string
  description = <<-EOT
    The time to wait for WinRM to become available. 
    
    This defaults to 30m since setting up a Windows machine generally takes a long time.
  EOT

  default = "30m"
}

variable "hv_winrm_use_ssl" {
  type        = bool
  description = "If true, use HTTPS for WinRM."
  default     = true
}

variable "hv_winrm_insecure" {
  type        = bool
  description = "If true, do not check server certificate chain and host name."
  default     = true
}

variable "hv_winrm_use_ntlm" {
  type        = bool
  description = <<-EOT
    If true, NTLMv2 authentication (with session security) will be used for WinRM, rather than default (basic authentication), 
      removing the requirement for basic authentication to be enabled within the target guest. 
      
    Further reading for remote connection authentication can be found:
      https://learn.microsoft.com/en-us/windows/win32/winrm/authentication-for-remote-connections?redirectedfrom=MSDN
  EOT

  default = false
}

# OPTIONAL SSH FIELDS
variable "hv_ssh_host" {
  type        = string
  description = "The address to SSH to. This usually is automatically configured by the builder."
  default     = null
}

variable "hv_ssh_port" {
  type        = number
  description = "The port to connect to SSH. This defaults to 22."
  default     = 22
}

variable "hv_ssh_username" {
  type        = string
  description = "The username to connect to SSH with. Required if using SSH."
  default     = "packer"
}

variable "hv_ssh_password" {
  type        = string
  sensitive   = true
  description = "A plaintext password to use to authenticate with SSH."
  default     = "SecretThingToChange!123"
}

variable "hv_ssh_ciphers" {
  type        = list(string)
  description = <<-EOT
    This overrides the value of ciphers supported by default by Golang. 
    
    The default value is [ "aes128-gcm@openssh.com", "chacha20-poly1305@openssh.com", "aes128-ctr", "aes192-ctr", "aes256-ctr", ]

    Valid options for ciphers include: 
      - "aes128-ctr"
      - "aes192-ctr"
      - "aes256-ctr"
      - "aes128-gcm@openssh.com"
      - "chacha20-poly1305@openssh.com"
      - "arcfour256"
      - "arcfour128"
      - "arcfour"
      - "aes128-cbc"
      - "3des-cbc"
  EOT

  default = null
}

variable "hv_ssh_clear_authorized_keys" {
  type        = bool
  description = <<-EOT
    If true, Packer will attempt to remove its temporary key from ~/.ssh/authorized_keys and /root/.ssh/authorized_keys. 
    
    This is a mostly cosmetic option, since Packer will delete the temporary private key from the host system regardless 
      of whether this is set to true (unless the user has set the -debug flag). 
      
    Defaults to "false"; currently only works on guests with sed installed.
  EOT

  default = false
}

variable "hv_ssh_key_exchange_algorithms" {
  type        = list(string)
  description = <<-EOT
    If set, Packer will override the value of key exchange (kex) algorithms supported by default by Golang. 
    
    Acceptable values include: 
      - "curve25519-sha256@libssh.org"
      - "ecdh-sha2-nistp256"
      - "ecdh-sha2-nistp384"
      - "ecdh-sha2-nistp521"
      - "diffie-hellman-group14-sha1"
      - "diffie-hellman-group1-sha1".
  EOT

  default = null
}

variable "hv_ssh_certificate_file" {
  type        = string
  description = <<-EOT
    Path to user certificate used to authenticate with SSH. 
    
    The ~ can be used in path and will be expanded to the home directory of current user.
  EOT

  default = null
}

variable "hv_ssh_pty" {
  type        = bool
  description = "If true, a PTY will be requested for the SSH connection. This defaults to false."
  default     = false
}

variable "hv_ssh_timeout" {
  type        = string
  description = <<-EOT
    The time to wait for SSH to become available. 
    
    Packer uses this to determine when the machine has booted so this is usually quite long. 
    
    Example value: 10m. This defaults to 5m, unless ssh_handshake_attempts is set.
  EOT

  default = "5m"
}

variable "hv_ssh_disable_agent_forwarding" {
  type        = bool
  description = "If true, SSH agent forwarding will be disabled. Defaults to false."
  default     = false
}

variable "hv_ssh_handshake_attempts" {
  type        = number
  description = "The number of handshakes to attempt with SSH once it can connect. This defaults to 10, unless a ssh_timeout is set."
  default     = 10
}

variable "hv_ssh_bastion_host" {
  type        = string
  description = "A bastion host to use for the actual SSH connection."
  default     = null
}

variable "hv_ssh_bastion_port" {
  type        = number
  description = "The port of the bastion host. Defaults to 22."
  default     = 22
}

variable "hv_ssh_bastion_agent_auth" {
  type        = bool
  description = "If true, the local SSH agent will be used to authenticate with the bastion host. Defaults to false."
  default     = false
}

variable "hv_ssh_bastion_username" {
  type        = string
  description = "The username to connect to the bastion host."
  default     = "packer"
}

variable "hv_ssh_bastion_password" {
  type        = string
  sensitive   = true
  description = "The password to use to authenticate with the bastion host."
  default     = "SecretThingToChange!123"
}

variable "hv_ssh_bastion_interactive" {
  type        = bool
  description = "If true, the keyboard-interactive used to authenticate with bastion host."
  default     = false
}

variable "hv_ssh_bastion_private_key_file" {
  type        = string
  description = <<-EOT
    Path to a PEM encoded private key file to use to authenticate with the bastion host. 
    
    The ~ can be used in path and will be expanded to the home directory of current user.
  EOT

  default = null
}

variable "hv_ssh_bastion_certificate_file" {
  type        = string
  description = <<-EOT
    Path to user certificate used to authenticate with bastion host. 
    
    The ~ can be used in path and will be expanded to the home directory of current user.
  EOT

  default = null
}

variable "hv_ssh_file_transfer_method" {
  type        = string
  description = <<-EOT
    scp or sftp - How to transfer files, Secure copy (default) or SSH File Transfer Protocol.

    NOTE: Guests using Windows with Win32-OpenSSH v9.1.0.0p1-Beta, scp (the default protocol for copying data) returns a
      non-zero error code since the MOTW cannot be set, which cause any file transfer to fail. 
      
    As a workaround you can override the transfer protocol with SFTP instead ssh_file_transfer_protocol = "sftp".
  EOT

  default = "scp"
}

variable "hv_ssh_proxy_host" {
  type        = string
  description = "A SOCKS proxy host to use for SSH connections."
  default     = null
}

variable "hv_ssh_proxy_port" {
  type        = number
  description = "A port of the SOCKS proxy. Defaults to 1080."
  default     = 1080
}

variable "hv_ssh_proxy_username" {
  type        = string
  description = "The optional username to authenticate with the proxy server."
  default     = "packer"
}

variable "hv_ssh_proxy_password" {
  type        = string
  sensitive   = true
  description = "The optional password to use to authenticate with the proxy server."
  default     = "SecretThingToChange!123"
}

variable "hv_ssh_keep_alive_interval" {
  type        = string
  description = <<-EOT
     How often to send "keep alive" messages to the server. 
     
     Set to a negative value (-1s) to disable. Example value: 10s. Defaults to 5s.
  EOT

  default = "5s"
}

variable "hv_ssh_read_write_timeout" {
  type        = string
  description = <<-EOT
    The amount of time to wait for a remote command to end. 
    
    This might be useful if, for example, packer hangs on a connection after a reboot. Example: 5m. Disabled by default.
  EOT

  default = null
}

variable "hv_ssh_remote_tunnels" {
  type        = list(string)
  description = "Packer currently doesn't have this doucmented: https://github.com/hashicorp/packer-plugin-sdk/blob/main/communicator/config.go"
  default     = null
}

variable "hv_ssh_local_tunnels" {
  type        = list(string)
  description = "Packer currently doesn't have this doucmented: https://github.com/hashicorp/packer-plugin-sdk/blob/main/communicator/config.go"
  default     = null
}

variable "hv_ssh_private_key_file" {
  type        = string
  description = <<-EOT
    Path to a PEM encoded private key file to use to authenticate with SSH. 
    
    The ~ can be used in path and will be expanded to the home directory of current user.
  EOT

  default = null
}

# BOOT CONFIGURATION REFERENCE
variable "hv_boot_command" {
  type        = list(string)
  description = <<-EOT
    The boot configuration is very important: boot_command specifies the keys to type when the virtual machine 
      is first booted in order to start the OS installer. 
      
    This command is typed after boot_wait, which gives the virtual machine some time to actually load.

    The boot_command is an array of strings. The strings are all typed in sequence. It is an array only to improve readability within the template.

    There are a set of special keys available. If these are in your boot command, they will be replaced by the proper key:
      * <bs> - Backspace
      * <del> - Delete
      * <enter> <return> - Simulates an actual "enter" or "return" keypress.
      * <esc> - Simulates pressing the escape key.
      * <tab> - Simulates pressing the tab key.
      * <f1> - <f12> - Simulates pressing a function key.
      * <up> <down> <left> <right> - Simulates pressing an arrow key.
      * <spacebar> - Simulates pressing the spacebar.
      * <insert> - Simulates pressing the insert key.
      * <home> <end> - Simulates pressing the home and end keys.
      * <pageUp> <pageDown> - Simulates pressing the page up and page down keys.
      * <menu> - Simulates pressing the Menu key.
      * <leftAlt> <rightAlt> - Simulates pressing the alt key.
      * <leftCtrl> <rightCtrl> - Simulates pressing the ctrl key.
      * <leftShift> <rightShift> - Simulates pressing the shift key.
      * <leftSuper> <rightSuper> - Simulates pressing the ⌘ or Windows key.
      * <wait> <wait5> <wait10> - Adds a 1, 5 or 10 second pause before sending any additional keys. 
          This is useful if you have to generally wait for the UI to update before typing more.
      * <waitXX> - Add an arbitrary pause before sending any additional keys. 
          
          The format of XX is a sequence of positive decimal numbers, each with optional 
            fraction and a unit suffix, such as 300ms, 1.5h or 2h45m. 
            
          Valid time units are ns, us (or µs), ms, s, m, h. For example <wait10m> or <wait1m20s>.
      * <XXXOn> <XXXOff> - Any printable keyboard character, and of these "special" expressions, 
          with the exception of the <wait> types, can also be toggled on or off. 
            
          For example, to simulate ctrl+c, use <leftCtrlOn>c<leftCtrlOff>. 
          Be sure to release them, otherwise they will be held down until the machine reboots. 
          To hold the c key down, you would use <cOn>. Likewise, <cOff> to release.
      * {{ .HTTPIP }} {{ .HTTPPort }} - The IP and port, respectively of an HTTP server that is started serving the 
          directory specified by the http_directory configuration parameter. 
          
          If http_directory isn't specified, these will be blank!
      * {{ .Name }} - The name of the VM.

      If this is not specified, it is assumed the installer will start itself.
  EOT

  default = null
}

variable "hv_boot_keygroup_interval" {
  type        = string
  description = <<-EOT
     Time to wait after sending a group of key pressses. 
     
     The value of this should be a duration. 
     
     Examples are 5s and 1m30s which will cause Packer to wait five seconds and one minute 30 seconds, respectively. 
     
     If this isn't specified, a sensible default value is picked depending on the builder type.
  EOT

  default = null
}

variable "hv_boot_wait" {
  type        = string
  description = <<-EOT
    The time to wait after booting the initial virtual machine before typing the boot_command. 
    
    The value of this should be a duration. 
    
    Examples are 5s and 1m30s which will cause Packer to wait five seconds and one minute 30 seconds, respectively. 
    
    If this isn't specified, the default is 10s or 10 seconds. To set boot_wait to 0s, use a negative number, such as "-1s"
  EOT

  default = "1s"
}