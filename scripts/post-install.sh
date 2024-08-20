#!/usr/bin/env sh

set -e

# Install useful package
pkg install -y base64

# Disable SSH password authentication
echo "Disabling SSH password in OPNSense configuration"
sed -i '' '/<passwordauth>1<\/passwordauth>/d' /conf/config.xml

echo "Shutting the VM down"
shutdown -p now
