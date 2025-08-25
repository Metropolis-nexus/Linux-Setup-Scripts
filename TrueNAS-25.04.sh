#!/bin/sh

# Copyright (C) 2025 Thien Tran
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

# You need to add either the non-subscription repo or the testing repo from the Proxmox WebUI after running this script.

output(){
    printf '\e[1;34m%-6s\e[m\n' "${@}"
}

unpriv(){
    sudo -u nobody "$@"
}

# Compliance
sudo systemctl mask debug-shell.service

# Setting umask to 077
umask 077
sudo sed -i 's/^UMASK.*/UMASK 077/g' /etc/login.defs
echo "umask 077" | sudo tee -a /etc/zsh/zshrc

# Setup NTS
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/refs/heads/main/etc/chrony/conf.d/10-custom.conf | tee /etc/chrony/conf.d/10-custom.conf > /dev/null
chmod 644 /etc/chrony/conf.d/10-custom.conf
systemctl restart chronyd

# Harden SSH
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/ssh/sshd_config.d/10-custom.conf | sudo tee /etc/ssh/sshd_config.d/10-custom.conf > /dev/null
sudo chmod 644 /etc/ssh/sshd_config.d/10-custom.conf
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/ssh/ssh_config.d/10-custom.conf | sudo tee /etc/ssh/ssh_config.d/10-custom.conf > /dev/null
sudo chmod 644 /etc/ssh/ssh_config.d/10-custom.conf
sudo mkdir -p /etc/systemd/system/sshd.service.d/
sudo chmod 755 /etc/systemd/system/sshd.service.d/
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/systemd/system/sshd.service.d/override.conf | sudo tee /etc/systemd/system/sshd.service.d/override.conf > /dev/null
sudo systemctl daemon-reload
sudo systemctl restart sshd

# Kernel hardening
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/modprobe.d/server-blacklist.conf | sudo tee /etc/modprobe.d/server-blacklist.conf > /dev/null
sed -i 's/^install squashfs/#install squashfs/' /etc/modprobe.d/server-blacklist.conf
sudo chmod 644 /etc/modprobe.d/server-blacklist.conf
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/sysctl.d/99-server.conf | sudo tee /etc/sysctl.d/99-server.conf > /dev/null
sudo chmod 644 /etc/sysctl.d/99-server.conf
sudo sysctl -p

# Disable coredump
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/security/limits.d/30-disable-coredump.conf | sudo tee /etc/security/limits.d/30-disable-coredump.conf > /dev/null
sudo chmod 644 /etc/security/limits.d/30-disable-coredump.conf
sudo mkdir -p /etc/systemd/coredump.conf.d
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/systemd/coredump.conf.d/disable.conf | sudo tee /etc/systemd/coredump.conf.d/disable.conf > /dev/null
sudo chmod 644 /etc/systemd/coredump.conf.d/disable.conf
