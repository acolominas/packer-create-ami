#!/usr/bin/env sh

set -ex

echo "Download OPNSense""$PKR_VAR_VERSION"" from ""$PKR_VAR_MIRROR"

download() {
  mkdir -p iso

  curl --output iso/OPNsense-"$PKR_VAR_VERSION"-dvd-amd64.iso.bz2 "$PKR_VAR_MIRROR"/releases/"$PKR_VAR_VERSION"/OPNsense-"$PKR_VAR_VERSION"-dvd-amd64.iso.bz2

  bzip2 -d iso/OPNsense-"$PKR_VAR_VERSION"-dvd-amd64.iso.bz2
}

download
