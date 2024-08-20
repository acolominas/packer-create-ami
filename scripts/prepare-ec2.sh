#!/bin/sh

# replace <if></if> section of config.xml with proper names for running on AWS EC2
sed -i -E 's$<if>em0</if>$<if>en0</if>$g' /conf/config.xml

# print grep results for verification during packer build:
echo "grep -H <if> ... output:"
grep -H '<if>' /conf/config.xml
