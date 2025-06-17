# Linux Setup Scripts

![ShellCheck](https://github.com/Metropolis-nexus/Linux-Setup-Scripts/actions/workflows/shellcheck.yml/badge.svg)

Generic Linux setup scripts. Edit them to your liking before running them.

## Notes
These configurations are tailored for Metropolis.nexus environment:
- Firewalling is handled by Proxmox (not the individual VMs)
- DNSSEC validation is done by either OPNsense or a central VM dedicated to running the DNS resolver
- `io_uring` is disabled. On Proxmox, use `aio=native` for drives. You will need to manually edit the config for cdrom. Alternatively, if you do not want to deal with this, comment out the io_uring line in `/etc/sysctl.d/99-server.conf`