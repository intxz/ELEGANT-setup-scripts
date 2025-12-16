#!/bin/bash
set -e

#
# perfSONAR script for Ubuntu
# Based on: https://docs.perfsonar.net/
#

echo ">>> Installing prerequisites..."
sudo apt install -y curl
sudo curl -o /etc/apt/sources.list.d/perfsonar-release.list https://downloads.perfsonar.net/debian/perfsonar-release.list
sudo curl -s -o /etc/apt/trusted.gpg.d/perfsonar-release.gpg.asc https://downloads.perfsonar.net/debian/perfsonar-release.gpg.key

sudo apt update
sudo apt install owamp-server owamp-client

echo "############# OWAMPD INSTALLATION COMPLETED SUCCESSFULLY #############"

sudo systemctl status owamp-server --no-pager