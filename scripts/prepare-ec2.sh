#!/bin/sh

OS_VERSION=$(uname -r | cut -d'.' -f1)
ARCH=$(uname -m)

echo "Install SSM-Agent and configuring"
#Install ssm-agent from FreeBSD repository
pkg add https://pkg.freebsd.org/FreeBSD:${VERSION}:${ARCH}/latest/All/amazon-ssm-agent-2.3.1205.0_25.pkg

#Install EC2 Scripts
pkg add https://pkg.freebsd.org/FreeBSD:${VERSION}:${ARCH}/latest/All/aws-ec2-imdsv2-get-1.0.5_6.pkg
pkg add https://pkg.freebsd.org/FreeBSD:${VERSION}:${ARCH}/latest/All/ebsnvme-id-1.0.3_1.pkg
pkg add https://pkg.freebsd.org/FreeBSD:${VERSION}:${ARCH}/latest/All/ec2-scripts-1.12.pkg



#Add permssions to ssm-user to gain root privileges
echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > /usr/local/etc/sudoers.d/ssm-agent-users

#Enable service
service amazon-ssm-agent enable


# replace <if></if> section of config.xml with proper names for running on AWS EC2
sed -i -E 's$<if>em0</if>$<if>ena0</if>$g' /conf/config.xml
sed -i -E 's|<ipaddr>.*</ipaddr>|<ipaddr>dhcp</ipaddr>|g' /conf/config.xml
# print grep results for verification during packer build:
echo "grep -H <if> ... output:"
grep -H '<if>' /conf/config.xml
grep -H '<ipaddr>' /conf/config.xml
