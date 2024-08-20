packer {
  required_plugins {
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "iso_checksum" {
  type    = string
  default = "6e08216183c50da1601bd69c49ffcb66a0c998ca4352f7b811b4025499597fa5"
}

variable "iso_name" {
  type    = string
  default = "netgate-installer-amd64"
}

variable "vm_name" {
  type    = string
  default = "pfSense-CE-2.7.2"
}

# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "virtualbox-iso" "pfsense" {
  boot_command = [
    "<wait5><enter>",
    "<wait5><enter>",
    "<wait5><enter>",
    "<wait5><down>",
    "<wait5><enter>",
    "<wait5><left>",
    "<wait5><enter>",
    "<wait5><enter>",
    "<wait5><down>",
    "<wait5><enter>",
    "<wait5><enter>",
    "<wait5><enter>",
    "<wait10><wait10><wait10><wait10><enter>",
    "<wait5><enter>",
    "<wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10>",
    "8<wait5><enter>",
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/config.xml >/conf/config.xml<wait5><enter>",
    "reboot<wait5><enter>"
  ]
  boot_wait            = "30s"
  disk_size            = "4096"
  format               = "ovf"
  guest_additions_mode = "disable"
  guest_os_type        = "FreeBSD_64"
  headless             = "false"
  http_directory       = "config"
  http_port_min        = "8100"
  iso_checksum         = "${var.iso_checksum}"
  iso_url              = "iso/${var.iso_name}.iso"
  output_directory     = "output"
  shutdown_command     = "shutdown -p now"
  ssh_password         = "pfsense"
  ssh_port             = "22"
  ssh_username         = "root"
  ssh_wait_timeout     = "3600s"
  vboxmanage           = [["modifyvm", "{{ .Name }}", "--boot1", "disk"], ["modifyvm", "{{ .Name }}", "--boot2", "dvd"], ["modifyvm", "{{ .Name }}", "--cpus", "1"], ["modifyvm", "{{ .Name }}", "--memory", "1024"], ["modifyvm", "{{ .Name }}", "--natpf1", "https,tcp,,7373,,7373"], ["modifyvm", "{{ .Name }}", "--nic2", "intnet"]]
  vm_name              = "${var.vm_name}_${local.timestamp}"
  vrdp_bind_address    = "127.0.0.1"
  vrdp_port_max        = "3389"
  vrdp_port_min        = "3389"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.virtualbox-iso.pfsense"]

}
