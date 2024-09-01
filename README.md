# sense-create-ami
In AWS if you want to use the official OPNsense or pfSense AMI you have subscribe to it in AWS Maketplace and pay to use them (+ infrastructure cost)

- [OPNsense](https://aws.amazon.com/marketplace/pp/prodview-lu5v2tokic3py?sr=0-1&ref_=beagle&applicationId=AWSMPContessa "OPNsense")
- [pfSense](https://aws.amazon.com/marketplace/pp/prodview-gzywopzvznrr4?sr=0-2&ref_=beagle&applicationId=AWSMPContessa "pfSense")

This repository contains the packer code to create pfSense and OPNsense AMIs and use them without paying.

This repository is based on these other repositories:
- https://github.com/remlabm/opnsense-packer
- https://github.com/aoktox/aws-pfsense-ami
- https://gitlab.com/open-images/opnsense

## Considerations
At the time of creating this repository, AWS does not allow you to directly import the Virtual Machine into an AMI because FreeBSD is not supported.  [List of supported operating systems](https://docs.aws.amazon.com/vm-import/latest/userguide/prequires.html "List of supported operating systems").
The only way is to upload the disk to s3, convert the disk to a snapshot, and then create the AMI.

During the installation process is possible that the ````<wait>```` times could change depending on the machine.

## Requirements
- jq
- Terraform
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

## How to use
First of all, you have to download the official ISO images and save it in **iso** folder:
- [OPNSense](https://opnsense.org/download/ "OPNSense")
- [pfSense - (It's mandatory to use an email)](https://www.pfsense.org/download/ "pfSense")

There is a makefile to make easier the use of this repository.
````sh
make install-prerequisites #deploy s3 bucket and IAM Service Role for VM-Import
make build-opnsense #launch the process of installation and create the AMI for OPNsense
make build-pfsense  #launch the process of installation and create the AMI for pfSense
make clean-builds #remove all disks and virtual machines in output directory
````

After deploying the AMI, access to OPNSense via Web Browser: https://EC2_Public_IP, user root, password opnsense
The access via SSH with root user is disabled, you need to access via ec2-user and the EC2 Key Pair configured.
