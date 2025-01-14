#!/usr/bin/env bash

# Fail if one command fails
set -e

# Run in non-interactive mode
export DEBIAN_FRONTEND=noninteractive

echo $(whoami) > /home/serveradmin/whoami.txt
#### DOCKER INSTALL ####
# Add Docker's official GPG key:
apt update -y
apt install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y

# Install docker
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Create docker group if it doesn't exist
if ! getent group docker > /dev/null; then
  groupadd docker
fi

# Add user to docker group
usermod -aG docker serveradmin