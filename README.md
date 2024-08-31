# sense-create-ami
In AWS if you want to use the OPNsesne or Pfsense official AMI you have to pay.
This repository contains the packer code to build Pfsense or OPNsense AMIs and use it without paying.

## Considerations
At the time of creation of this repostory, AWS doesn't allow to import directly the Virtual Machine to a AMI. FreeBSD is not supported.  [List of supported OS](https://docs.aws.amazon.com/vm-import/latest/userguide/prerequisites.html "List of supported OS").
The only way is to upload the disk to s3, convert the disk to an snapshot and then create the AMI.

## Requirements
- Packer
- Virtual-Box
- S3 Bucket and a service role linked to vm-import service.

## Features
- Cloud-Init installed and configured
  - Automatically resizes root filesystem
  - Adds SSH Keys
  - Configures a EC2-User with sudo permissions
- SSM Agent installed
- OPNsense is automatically upgraded to the latest packages

After deploying the AMI, access to OPNSense via Web Browser: https://EC2_Public_IP, user root, password opnsense
The access via SSH with root user is disabled, you need to access via ec2-user and the EC2 Key Pair configured.
