#!/usr/bin/env sh

set -e

#Install ssm-agent from FreeBSD repository
pkg add https://pkg.freebsd.org/FreeBSD:14:amd64/latest/All/amazon-ssm-agent-2.3.1205.0_25.pkg

#Add permssions to ssm-user to gain root privileges
echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > /usr/local/etc/sudoers.d/ssm-agent-users

#Enable service
service amazon-ssm-agent enable
