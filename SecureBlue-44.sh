#!/bin/bash

# Copyright (C) 2026 Thien Tran
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

umask 077

ujust dns-selector # Switch to systemd-resolved
ujust set-kargs-hardening # Disable 32 bit emulation, disable hyperthread (doesn't do anything), and enable unstable kernel arguments
ujust toggle-bash-environment-lockdown # Apply to all users
ujust set-webcam-modules off

ujust enroll-secureblue-secure-boot-key
ujust set-bluetooth-modules off
ujust set-brew off
ujust set-dhcp-hostname-sending off
ujust set-libvirt-daemons off
ujust set-xwayland off

ujust enable-flathub-unfiltered
ujust flatpak-permissions-lockdown
ujust harden-flatpak

ujust toggle-gnome-extensions
rpm-ostree install gnome-extensions-app gnome-shell-extension-appindicator gnome-shell-extension-blur-my-shell

# Setup dconf
curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/adw-gtk3-dark -o /etc/dconf/db/local.d/adw-gtk3-dark > /dev/null
curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/automount-disable -o /etc/dconf/db/local.d/automount-disable > /dev/null
curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/button-layout -o /etc/dconf/db/local.d/button-layout > /dev/null
curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/prefer-dark -o /etc/dconf/db/local.d/prefer-dark > /dev/null
curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/privacy -o /etc/dconf/db/local.d/privacy > /dev/null
curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/touchpad -o /etc/dconf/db/local.d/touchpad > /dev/null
chmod 644 /etc/dconf/db/local.d/*

mkdir -p /etc/dconf/db/local.d/locks
chmod 755 /etc/dconf/db/local.d/locks

curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/locks/automount-disable -o /etc/dconf/db/local.d/locks/automount-disable > /dev/null
curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/dconf/db/local.d/locks/privacy -o /etc/dconf/db/local.d/locks/privacy > /dev/null
chmod 644 /etc/dconf/db/local.d/locks/*

umask 022
dconf update
umask 077