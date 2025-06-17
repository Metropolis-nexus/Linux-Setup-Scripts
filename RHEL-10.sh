#!/bin/sh

# Copyright (C) 2021-2025 Thien Tran
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

set -eu

output(){
    printf '\e[1;34m%-6s\e[m\n' "${@}"
}

unpriv(){
    sudo -u nobody "$@"
}

# Compliance
sudo systemctl mask debug-shell.service
sudo systemctl mask kdump.service

# Setting umask to 077
umask 077
sudo sed -i 's/^UMASK.*/UMASK 077/g' /etc/login.defs
sudo sed -i 's/^HOME_MODE/#HOME_MODE/g' /etc/login.defs
sudo sed -i 's/umask 022/umask 077/g' /etc/bashrc

# Make home directory private
sudo chmod 700 /home/*

# Passwordless sudo
sudo sed -i 's/# %wheel/%wheel/' /etc/sudoers

# Remove nullok
sudo /usr/bin/sed -i 's/\s+nullok//g' /etc/pam.d/system-auth

# Setup NTS
sudo dnf install -y chrony
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/chrony.conf | sudo tee /etc/chrony.conf > /dev/null
sudo chmod 644 /etc/chrony.conf
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/sysconfig/chronyd | sudo tee /etc/sysconfig/chronyd > /dev/null
sudo chmod 644 /etc/sysconfig/chronyd
sudo systemctl restart chronyd

# Harden NetworkManager
sudo mkdir -p /etc/systemd/system/NetworkManager.service.d
unpriv curl -s https://gitlab.com/divested/brace/-/raw/master/brace/usr/lib/systemd/system/NetworkManager.service.d/99-brace.conf | sudo tee /etc/systemd/system/NetworkManager.service.d/99-brace.conf > /dev/null
sudo chmod 644 /etc/systemd/system/NetworkManager.service.d/99-brace.conf
sudo systemctl daemon-reload
sudo systemctl restart NetworkManager

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

# Security kernel settings
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/modprobe.d/server-blacklist.conf | sudo tee /etc/modprobe.d/server-blacklist.conf > /dev/null
sudo chmod 644 /etc/modprobe.d/server-blacklist.conf
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/sysctl.d/99-server.conf | sudo tee /etc/sysctl.d/99-server.conf > /dev/null
sudo chmod 644 /etc/sysctl.d/99-server.conf
sudo dracut -f
sudo sysctl -p

# efi=disable_early_pci_dma seems to break boot on RHEL and only RHEL, dunno why yet
sudo grubby --update-kernel=ALL --args='mitigations=auto,nosmt nosmt=force spectre_v2=on spectre_bhi=on spec_store_bypass_disable=on tsx=off l1d_flush=on l1tf=full,force kvm-intel.vmentry_l1d_flush=always spec_rstack_overflow=safe-ret gather_data_sampling=force reg_file_data_sampling=on kvm.nx_huge_pages=force amd_iommu=force_isolation intel_iommu=on iommu=force iommu.strict=1 iommu.passthrough=0 efi=disable_early_pci_dma slab_nomerge init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 pti=on randomize_kstack_offset=on lockdown=confidentiality module.sig_enforce=1 oops=panic vsyscall=none ia32_emulation=0 debugfs=off random.trust_bootloader=off random.trust_cpu=off console=tty0 console=ttyS0,115200'

# Disable coredump
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/security/limits.d/30-disable-coredump.conf | sudo tee /etc/security/limits.d/30-disable-coredump.conf > /dev/null
sudo chmod 644 /etc/security/limits.d/30-disable-coredump.conf
sudo mkdir -p /etc/systemd/coredump.conf.d
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/systemd/coredump.conf.d/disable.conf | sudo tee /etc/systemd/coredump.conf.d/disable.conf > /dev/null
sudo chmod 644 /etc/systemd/coredump.conf.d/disable.conf

# Setup DNF
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dnf/dnf.conf | sudo tee /etc/dnf/dnf.conf > /dev/null
sudo chmod 644 /etc/dnf/dnf.conf

# Upgrade all packages
sudo dnf upgrade -y

# Setup automatic updates
sudo dnf install -y dnf-automatic
sudo sed -i 's/apply_updates = no/apply_updates = yes\nreboot = when-needed/g' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic.timer

# Remove unnecessary packages
sudo systemctl disable --now firewalld
sudo systemctl disable --now irqbalance
## rhc provides the remote remediation feature - we don't want it
sudo dnf remove -y audit cockpit* cronie firewalld *firmware* flashrom grub2-tools-extra iptables* irqbalance hunspell* kdump-utils kpartx mdadm microcode_ctl parted pcsc* pigz pkgconf prefixdevname rhc rootfiles sg3* sssd* tpm2-tools  vim*

# Install hardened_malloc
# Not available on RHEL 10 yet
#sudo dnf copr enable secureblue/hardened_malloc -y
#sudo dnf install -y hardened_malloc
#echo 'libhardened_malloc.so' | sudo tee /etc/ld.so.preload
#sudo chmod 644 /etc/ld.so.preload

# Setup insights
sudo insights-client --register

# Install nano & guest agent
sudo dnf install -y nano qemu-guest-agent

# Enable auto TRIM
sudo systemctl enable fstrim.timer

# Setup tuned
sudo dnf install -y tuned
sudo systemctl enable --now tuned
sudo tuned-adm profile virtual-guest

# Setup notices
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/issue | sudo tee /etc/issue > /dev/null
sudo chmod 644 /etc/issue
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/issue | sudo tee /etc/issue.net > /dev/null
sudo chmod 644 /etc/issue.net
