#!/usr/bin/env sh

set -e

# Install Cloud-init
echo "Install Cloud-init package"
pkg install -y net/cloud-init

mkdir -p /etc/cloud/cloud.cfg.d/

cat <<EOF >/usr/local/etc/cloud/cloud.cfg.d/01-cloud.cfg
#cloud-config
# The top level settings are used as module
# and system configuration.
syslog_fix_perms: root:wheel

# If this is set, 'root' will not be able to ssh in and they
# will get a message to login instead as the default $user
disable_root: true

# This will cause the set+update hostname module to not operate (if true)
preserve_hostname: false

# If you use datasource_list array, keep array items in a single line.
# If you use multi line array, ds-identify script won't read array items.
# This should not be required, but leave it in place until the real cause of
# not finding -any- datasources is resolved.
#datasource_list: ['OpenStack', 'NoCloud', 'ConfigDrive', 'Azure', 'Ec2']
# Example datasource config
# datasource:
#    Ec2:
#      metadata_urls: [ 'blah.com' ]
#      timeout: 5 # (defaults to 50 seconds)
#      max_wait: 10 # (defaults to 120 seconds)


# The modules that run in the 'init' stage
cloud_init_modules:
  - seed_random
  - bootcmd
  - write_files
  - growpart
  - resizefs
  - set_hostname
  - update_hostname
  - update_etc_hosts
  - ca_certs
  - rsyslog
  - users_groups
  - ssh

# The modules that run in the 'config' stage
cloud_config_modules:
  - ssh_import_id
  - keyboard
  - locale
  - set_passwords
  - ntp
  - timezone
  - disable_ec2_metadata
  - runcmd

# The modules that run in the 'final' stage
cloud_final_modules:
  - package_update_upgrade_install
  - write_files_deferred
  - puppet
  - chef
  - ansible
  - mcollective
  - salt_minion
  - reset_rmc
  - scripts_vendor
  - scripts_per_once
  - scripts_per_boot
  - scripts_per_instance
  - scripts_user
  - ssh_authkey_fingerprints
  - keys_to_console
  - install_hotplug
  - phone_home
  - final_message
  - power_state_change

# System and/or distro specific settings
# (not accessible to handlers/transforms)
system_info:
   # This will affect which distro class gets used
   distro: freebsd
   default_user:
    name: ec2-user
    lock_passwd: True
    gecos: EC2 Default User
    groups: [wheel]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/sh
   network:
      renderers: ['freebsd']
growpart:
   mode: auto
   devices:
      - /dev/vtbd0p3
      - /dev/da0p3
      - /





EOF

sysrc cloudinit_enable="YES"
