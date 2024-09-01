#https://gitlab.com/open-images/opnsense


packer {
  required_plugins {
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1"
    }
  }
}


source "virtualbox-iso" "opnsense" {
  #BOOT_COMMAND
  #1. Boot in multi user mod
  #2. Waiting 4min for guest to start
  #3. Login into the firewall
  #4. Start manual interface assignment
  #5. Do not configure LAGGs now
  #6. Do not configure VLANs now
  #7. Configure WAN interfaces
  #8. Skip LAN interface configuration
  #9. Skip Optional interface 1 configuration
  #10. I want to proceed
  #11. Wait for OPNSense to reload
  #12. Enter in shell
  #13. Download config.xml
  #14. Run OPNsense Installer
  #15. Use default keymap
  #16. Use UFS
  #17. Select the disk and install OPNsense
  #18. Exit installer and wait 2min for guest to start
  #19. Login into the firewall
  #20. Disabling firewall

  boot_command = [
    "1",
    "<wait3m>",
    "root<enter><wait>opnsense<enter><wait3s>",
    "1<enter><wait>",
    "N<enter><wait>",
    "N<enter><wait>",
    "em0<enter><wait>",
    "<enter><wait>",
    "<enter><wait>",
    "y<enter><wait>",
    "<wait30s>",
    "<wait>8<enter><wait>",
    "curl -o /conf/config.xml http://{{ .HTTPIP }}:{{ .HTTPPort }}/config_opnsense.xml<enter><wait3s>",
    "opnsense-installer<enter><wait>",
    "<enter><wait>",
    "${local.select_install_type}<enter><wait3s>",
    "<down><enter><wait><left><enter><wait12m>",
    "<down><enter><wait3m>",
    "root<enter><wait>opnsense<enter><wait3s>",
    "8<enter><wait>pfctl -d<enter><wait>"
  ]
  boot_wait            = "3s"
  cpus                 = 2
  disk_size            = 10240
  guest_additions_mode = "disable"
  guest_os_type        = "FreeBSD_64"
  headless             = true
  http_directory       = "http"
  http_port_min        = "8100"
  iso_checksum         = var.ISO_CHECKSUM
  iso_url              = "./iso/OPNsense-${var.VERSION}-dvd-amd64.iso"
  memory               = 2048
  output_directory     = "output"
  shutdown_command     = "shutdown<enter>"
  ssh_password         = "opnsense"
  ssh_port             = 22
  ssh_username         = "root"
  ssh_wait_timeout     = "1000s"
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--boot1", "disk"],
    ["modifyvm", "{{ .Name }}", "--boot2", "dvd"],
    ["modifyvm", "{{ .Name }}", "--natpf1", "managinggui,tcp,127.0.0.1,10443,,443"],
    ["modifyvm", "{{ .Name }}", "--natpf1", "ssh,tcp,127.0.0.1,10022,,22"]
  ]
  virtualbox_version_file = ".vbox_version"
  vm_name                 = "${var.VN_NAME}-${var.VERSION}"
}

build {
  sources = ["source.virtualbox-iso.opnsense"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; /bin/sh -c '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "scripts/base.sh",
      "scripts/cloud-init.sh",
      "scripts/prepare-ec2.sh",
      "scripts/post-install.sh"
    ]
  }

  post-processor "shell-local" {
    inline = ["bash utils/import_snapshot_to_ami.sh ${var.S3_BUCKET_NAME}${var.VN_NAME} ${var.VERSION}"]
  }
}

variable "VN_NAME" {
  type    = string
  default = "OPNsense"
}


variable "VERSION" {
  type    = string
  default = "24.7"
  validation {
    condition     = can(regex("^\\d{2}\\.\\d$", var.VERSION))
    error_message = "The version should be XX.X. Ex: 24.1."
  }
}

variable "ISO_CHECKSUM" {
  type    = string
  default = "sha1:fa8897dc45faa84e20072dcd1fb4dde4ae4e915e"
  validation {
    condition     = can(regex("^\\w+:\\w+", var.ISO_CHECKSUM))
    error_message = "The ISO checksum should be <type>:<value>. Ex: sha1:2722ee32814ee722bb565ac0dd83d9ebc1b31ed9."
  }
}

variable "S3_BUCKET_NAME" {
  type    = string
  default = "acolominas-vmimport"
}



local "select_install_type" {
  # With OPNsense 24.7+, the default install is ZFS
  # With new version, we have to press <down> to select UFS install
  expression = convert(var.VERSION, number) < 24.7 ? "" : "<down>"
}
