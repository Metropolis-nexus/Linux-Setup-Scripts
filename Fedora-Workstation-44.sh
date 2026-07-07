#!/bin/sh

# Copyright (C) 2021-2026 Thien Tran
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

# Meant for quickly spinning up my personal Fedora Workstation instances.
# This is mainly written for VMWare Fusion on Apple Silicon.

set -e

output(){
    printf '\e[1;34m%-6s\e[m\n' "${@}"
}

unpriv(){
    sudo -u nobody "$@"
}

virtualization=$(systemd-detect-virt)

# Increase compression level
sudo sed -i 's/zstd:1/zstd/g' /etc/fstab

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

# Setup NTS
sudo rm -rf /etc/chrony.conf
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/refs/heads/main/etc/chrony.conf | sudo tee /etc/chrony.conf > /dev/null
sudo chmod 644 /etc/chrony.conf
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/sysconfig/chronyd | sudo tee /etc/sysconfig/chronyd > /dev/null
sudo chmod 644 /etc/sysconfig/chronyd
sudo systemctl restart chronyd

# Remove nullok
sudo /usr/bin/sed -i 's/\s+nullok//g' /etc/pam.d/system-auth

# Harden SSH
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/ssh/ssh_config.d/10-custom.conf | sudo tee /etc/ssh/ssh_config.d/10-custom.conf > /dev/null
sudo chmod 644 /etc/ssh/ssh_config.d/10-custom.conf

# Security kernel settings
unpriv curl -s https://raw.githubusercontent.com/secureblue/secureblue/live/files/system/usr/lib/modprobe.d/secureblue-framebuffer.conf | sudo tee /etc/modprobe.d/framebuffer-blacklist.conf > /dev/null
sudo chmod 644 /etc/modprobe.d/framebuffer-blacklist.conf
unpriv curl -s https://raw.githubusercontent.com/secureblue/secureblue/live/files/system/usr/lib/modprobe.d/secureblue.conf | sudo tee /etc/modprobe.d/workstation-blacklist.conf > /dev/null
sudo chmod 644 /etc/modprobe.d/workstation-blacklist.conf
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/sysctl.d/99-workstation.conf | sudo tee /etc/sysctl.d/99-workstation.conf > /dev/null
sudo chmod 644 /etc/sysctl.d/99-workstation.conf
sudo dracut -f
sudo sysctl -p

sudo grubby --update-kernel=ALL --args='mitigations=auto,nosmt spectre_v2=on spectre_bhi=on spec_store_bypass_disable=on tsx=off kvm.nx_huge_pages=force nosmt=force l1d_flush=on l1tf=full,force kvm-intel.vmentry_l1d_flush=always spec_rstack_overflow=safe-ret gather_data_sampling=force reg_file_data_sampling=on random.trust_bootloader=off random.trust_cpu=off intel_iommu=on amd_iommu=force_isolation efi=disable_early_pci_dma iommu=force iommu.passthrough=0 iommu.strict=1 slab_nomerge init_on_alloc=1 init_on_free=1 pti=on vsyscall=none ia32_emulation=0 page_alloc.shuffle=1 randomize_kstack_offset=on debugfs=off lockdown=confidentiality module.sig_enforce=1'

# Disable coredump
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/security/limits.d/30-disable-coredump.conf | sudo tee /etc/security/limits.d/30-disable-coredump.conf > /dev/null
sudo chmod 644 /etc/security/limits.d/30-disable-coredump.conf
sudo mkdir -p /etc/systemd/coredump.conf.d
sudo chmod 755 /etc/systemd/coredump.conf.d
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/systemd/coredump.conf.d/disable.conf | sudo tee /etc/systemd/coredump.conf.d/disable.conf > /dev/null
sudo chmod 644 /etc/systemd/coredump.conf.d/disable.conf

# Disable XWayland
# VM guest agents may need XWayland for copy-paste
if [ "$virtualization" = 'none' ]; then
    sudo mkdir -p /etc/systemd/user/org.gnome.Shell@wayland.service.d
    sudo chmod 755 /etc/systemd/user/org.gnome.Shell@wayland.service.d
    unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/systemd/user/org.gnome.Shell%40wayland.service.d/override.conf | sudo tee /etc/systemd/user/org.gnome.Shell@wayland.service.d/override.conf > /dev/null
    sudo chmod 644 /etc/systemd/user/org.gnome.Shell@wayland.service.d/override.conf
fi

# Disable GJS and WebkitGTK JIT
unpriv curl https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/environment | sudo tee -a /etc/environment

# Setup dconf
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/adw-gtk3-dark | sudo tee /etc/dconf/db/local.d/adw-gtk3-dark > /dev/null
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/automount-disable | sudo tee /etc/dconf/db/local.d/automount-disable > /dev/null
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/button-layout | sudo tee /etc/dconf/db/local.d/button-layout > /dev/null
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/prefer-dark | sudo tee /etc/dconf/db/local.d/prefer-dark > /dev/null
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/privacy | sudo tee /etc/dconf/db/local.d/privacy > /dev/null
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/touchpad | sudo tee /etc/dconf/db/local.d/touchpad > /dev/null
sudo chmod 644 /etc/dconf/db/local.d/*

mkdir -p /etc/dconf/db/local.d/locks
sudo chmod 755 /etc/dconf/db/local.d/locks

unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/locks/automount-disable | sudo tee /etc/dconf/db/local.d/locks/automount-disable > /dev/null
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/locks/privacy | sudo tee /etc/dconf/db/local.d/locks/privacy > /dev/null
sudo chmod 644 /etc/dconf/db/local.d/locks/*

umask 022
sudo dconf update
umask 077

# Setup ZRAM
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/systemd/zram-generator.conf | sudo tee /etc/systemd/zram-generator.conf > /dev/null
sudo chmod 644 /etc/systemd/zram-generator.conf

# Setup DNF
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dnf/dnf.conf | sudo tee /etc/dnf/dnf.conf > /dev/null
sudo chmod 644 /etc/dnf/dnf.conf
sudo sed -i 's/^metalink=.*/&\&protocol=https/g' /etc/yum.repos.d/*

# Remove unwanted groups
sudo dnf -y group remove libreoffice container-management desktop-accessibility

# Remove firefox packages
sudo dnf -y remove fedora-bookmarks fedora-chromium-config firefox mozilla-filesystem

# Remove Network + hardware tools packages
sudo dnf -y remove avahi cifs* '*cups' dmidecode dnsmasq mtr net-snmp-libs net-tools nfs-utils nmap-ncat nmap-ncat opensc openssh-server rsync rygel tcpdump teamd traceroute usb_modeswitch

# Remove support for some languages and spelling
sudo dnf -y remove '*anthy*' '*hangul*' ibus-typing-booster '*m17n*' '*pinyin*' words

# Remove codec + image + printers
sudo dnf -y remove sane* simple-scan

# Remove Active Directory + Sysadmin + reporting tools
sudo dnf -y remove 'sssd*' realmd cyrus-sasl-gssapi quota* dos2unix kpartx sos samba-client gvfs-smb

# Remove vm and virtual stuff
sudo dnf -y remove 'podman*' 'open-vm*' qemu-guest-agent 'hyperv*' spice-vdagent

# Remove NetworkManager
sudo dnf -y remove NetworkManager-ssh-gnome NetworkManager-openconnect-gnome NetworkManager-openvpn-gnome NetworkManager-vpnc-gnome ppp* ModemManager

# Remove Gnome apps
sudo dnf remove -y baobab decibels gnome-bluetooth gnome-calculator gnome-calendar gnome-characters gnome-classic* gnome-clocks gnome-color-manager gnome-connections \
    gnome-contacts gnome-disk-utility gnome-font-viewer gnome-logs gnome-maps gnome-remote-desktop gnome-shell-extension-apps-menu \
    gnome-shell-extension-background-logo gnome-shell-extension-launch-new-instance gnome-shell-extension-places-menu gnome-shell-extension-window-list gnome-text-editor \
    gnome-tour gnome-user* gnome-weather loupe showtime snapshot

# Remove apps
sudo dnf remove -y libreoffice* mediawriter yelp

# Remove other packages
sudo dnf remove -y lvm2 '*perl*'

# Update packages
sudo dnf -y upgrade

# Install hardened_malloc
sudo dnf copr enable secureblue/packages -y
echo "includepkgs=hardened_malloc
priority=20" | sudo tee -a '/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:secureblue:packages.repo'
sudo dnf install -y hardened_malloc
echo 'libhardened_malloc.so' | sudo tee /etc/ld.so.preload
sudo chmod 644 /etc/ld.so.preload

# Install packages that I use
sudo dnf -y install adw-gtk3-theme gnome-extensions-app gnome-shell-extension-appindicator gnome-shell-extension-blur-my-shell

# Install appropriate virtualization drivers
if [ "$virtualization" = 'kvm' ]; then
    sudo dnf install -y qemu-guest-agent spice-vdagent
elif [ "$virtualization" = 'vmware' ]; then
    sudo dnf install -y open-vm-tools-desktop
fi

# Install Microsoft Edge if x86_64
MACHINE_TYPE=$(uname -m)
if [ "${MACHINE_TYPE}" = 'x86_64' ]; then
    output 'x86_64 machine, installing Microsoft Edge.'
    echo '[microsoft-edge]
name=microsoft-edge
baseurl=https://packages.microsoft.com/yumrepos/edge/
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc' | sudo tee /etc/yum.repos.d/microsoft-edge.repo
    sudo chmod 644 /etc/yum.repos.d/microsoft-edge.repo
    sudo dnf install -y microsoft-edge-stable
    sudo mkdir -p /etc/opt/edge/policies/managed/ /etc/opt/edge/policies/recommended/
    sudo chmod -R 755 /etc/opt
    unpriv curl -s https://raw.githubusercontent.com/TommyTran732/Microsoft-Edge-Policies/main/Linux/managed.json | sudo tee /etc/opt/edge/policies/managed/managed.json > /dev/null
    unpriv curl -s https://raw.githubusercontent.com/TommyTran732/Microsoft-Edge-Policies/main/Linux/recommended.json | sudo tee /etc/opt/edge/policies/recommended/recommended.json > /dev/null
    sudo chmod 644 /etc/opt/edge/policies/managed/managed.json /etc/opt/edge/policies/recommended/recommended.json
    sudo mkdir -p /usr/local/share/applications
    sudo chmod 755 /usr/local/share/applications
    sed 's/^Exec=\/usr\/bin\/microsoft-edge-stable/& --ozone-platform=wayland --start-maximized/g' /usr/share/applications/microsoft-edge.desktop | sudo tee /usr/local/share/applications/microsoft-edge.desktop
    sudo chmod 644 /usr/local/share/applications/microsoft-edge.desktop
else
    unpriv curl https://repo.secureblue.dev/secureblue.repo | sudo tee /etc/yum.repos.d/secureblue.repo
    sudo chmod 644 /etc/yum.repos.d/secureblue.repo
    echo "includepkgs=trivalent
priority=20" | sudo tee -a '/etc/yum.repos.d/secureblue.repo'
    sudo dnf install -y trivalent
fi

# Enable auto TRIM
sudo systemctl enable fstrim.timer

### Differentiating bare metal and virtual installs

# Setup fwupd
echo 'UriSchemes=file;https' | sudo tee -a /etc/fwupd/fwupd.conf
sudo systemctl restart fwupd

# Setup tuned
sudo dnf install -y tuned
sudo systemctl enable --now tuned
sudo tuned-adm profile virtual-guest

# Setup networking
sudo systemctl enable --now firewalld
sudo firewall-cmd --set-default-zone=block
sudo firewall-cmd --permanent --add-service=dhcpv6-client
sudo firewall-cmd --reload

unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/NetworkManager/conf.d/00-macrandomize.conf | sudo tee /etc/NetworkManager/conf.d/00-macrandomize.conf > /dev/null
sudo chmod 644 /etc/NetworkManager/conf.d/00-macrandomize.conf
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/NetworkManager/conf.d/01-transient-hostname.conf | sudo tee /etc/NetworkManager/conf.d/01-transient-hostname.conf > /dev/null
sudo chmod 644 /etc/NetworkManager/conf.d/01-transient-hostname.conf
sudo nmcli general reload conf
sudo hostnamectl hostname 'localhost'
sudo hostnamectl --transient hostname ''

sudo mkdir -p /etc/systemd/system/NetworkManager.service.d
unpriv curl -s https://gitlab.com/divested/brace/-/raw/master/brace/usr/lib/systemd/system/NetworkManager.service.d/99-brace.conf | sudo tee /etc/systemd/system/NetworkManager.service.d/99-brace.conf > /dev/null
sudo chmod 644 /etc/systemd/system/NetworkManager.service.d/99-brace.conf
sudo systemctl daemon-reload
sudo systemctl restart NetworkManager