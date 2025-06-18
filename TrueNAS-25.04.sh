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

# Setup NTS
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/refs/heads/main/etc/chrony/conf.d/10-custom.conf | tee /etc/chrony/conf.d/10-custom.conf > /dev/null
systemctl restart chronyd

# Configure sysctl
unpriv curl -s https://raw.githubusercontent.com/Metropolis-nexus/Common-Files/main/etc/sysctl.d/99-server.conf | tee /etc/sysctl.d/tuneables.conf > /dev/null
sysctl -p