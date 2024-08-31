#!/usr/bin/env sh

set -e

# Install useful package
echo "Install useful package"
pkg install -y base64 vim

#upgrade opnsense
echo "Upgrading OPNsense"
pkg clean -ay
opnsense-update -bkp

# Disable SSH password authentication
echo "Disabling SSH password in OPNSense configuration"
sed -i '' '/<passwordauth>1<\/passwordauth>/d' /conf/config.xml

echo "Shutting the VM down"
shutdown -p now
