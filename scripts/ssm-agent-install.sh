#!/usr/bin/env sh

set -e

pkg install -y amazon-ssm-agent

service amazon-ssm-agent enable
