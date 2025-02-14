# Ansible

A collection of ansible's playbooks to manage an infrastructure.


Actively maintained and in use at Kaminot

Supports:
- Debian
- FreeBSD
- OpenBSD
- Fedora

## Roles

It consist of a few roles:
* __Common__: ssh and user configurations that should be present on all our servers (**Fedora and Debian**)
* __proxmox__: Installs proxmox and set up the ldap authentication (**Debian**)
* __k3s__: set up the firewall rules as well as the docker dependency, depends on containerd and docker (**Debian**)

### Common

This role sets up the basic configs common to all systems:
* Install base packages `base[${HOST_FLAVOUR}_packages]`


#### Setup zabbix agent
* `zabbix_api_key` for dynamic host creation ** In progress **
* `zabbix`
  * `ca_key_passphrase` as ansible generates host certificates
  * `ownca_key_path` path to the ca key path
  * `ownca_cert_path` path to the ca certificate path

#### Set up on fedora LDAP authentication
* `ldap`
  * `debug_level` on the host (usefull when implementing)
  * `base_dn` the dn you want to search user in
  * `sudoers_base` base dn where the sudoers are located
  * `group_base` base dn where the groups are located
  * `server` ldap server
  * `ca`: the certificate of the ca to trust for auth

#### Set up users
* `active_users`
  * `name` the user name
  * `state` present, absent useful for removing users
  * `user_password` the user hash to copy to `/etc/passwd`
  * `ssh_key` a list of all the ssh-key the user should have

## Adding and removing users

User are defined as group variables (all) in there you will find a *state* variables
* _present_: means makes sure the user is active
* _absent_: makes sure the user is deleted

## Specificities to playbooks

### Common

All the variables are defined in `group_vars`

The variables for zabbix are present in the task vars, it rewrites all lines **WIP**

### Asterisk

This configures the certificate renewal for asterisk using a caddy instance.

Copy the certificate in `/etc/asterisk/certs/asterisk.crt` and key to `/etc/asterisk/certs/asterisk.key` if you want to change it you will need to modify the template `asterisk_renewal_script.sh`


Add in the task variable the `acme.email` for let's encrypt

### Proxmox

2 variables needs to be defined:
* `name` _[string]_: the domain name
 * `ldap_server` _[string]_: the dns name of the ldap server

### K3S
**This playbook considers that docker and containerd are already installed**

A few variables needs to be specified
* `k3s_ingress.port` _[list]_: all the port that should be doing ingress (firewall accept rules)
* `k3s.hosts4` _[list]_: list of all the ipv4 hosts that should communicate with the control plane
* `k3s.hosts6` _[list]_: list of all the ipv6 hosts that should communicate with the control plane

### BGP Bird

Sets up a small fdd with bird **WIP**

### Kubernetes

Set up the base packages for kubernetes, installs v1.30 atm

### Ldap Auth

Sets up the ldap_auth only for fedora at the moment
