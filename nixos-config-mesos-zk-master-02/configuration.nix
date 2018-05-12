# configuration.nix
{ boot, filesystems, networking, services, swapDevices, ... }: 

# import our config.json settings
let 
  d = {
    common = (with builtins; fromJSON(builtins.readFile /etc/nixos/config/config.json)).common;
    # make sure we swallow the right leaf node property
    my = (with builtins; fromJSON(builtins.readFile /etc/nixos/config/config.json)).mesos_masters.node02;
  };

in {

  nixpkgs.config.allowBroken = true;

  imports = [
    ./common/imports.nix
    ./pkgs.nix
    /etc/nixos/common/mesos-master-services.nix
    /etc/nixos/common/obor-watchdog.nix
    # we need to import this only if we're on AWS
    <nixpkgs/nixos/modules/virtualisation/amazon-image.nix>
  ];

  # we need to enable this only if we're on AWS
  ec2.hvm = true;

  networking = {
    hostName = "${d.my.hostname}";

    # and update /etc/hosts
    extraHosts = ''
      127.0.0.1 ${d.my.hostname} ${d.my.public_fqdn}
      ${d.common.etc_hosts_entries}
    '';
  };

  boot.initrd.availableKernelModules = [ "ata_piix" ];

  security.sudo.configFile =
    ''
      Defaults:root,%wheel env_keep+=LOCALE_ARCHIVE
      Defaults:root,%wheel env_keep+=NIX_PATH
      Defaults:root,%wheel env_keep+=TERMINFO_DIRS
      Defaults env_keep+=SSH_AUTH_SOCK
      Defaults lecture = never
      root   ALL=(ALL) SETENV: ALL
      %wheel ALL=(ALL) NOPASSWD: ALL, SETENV: ALL
    '';

  swapDevices = [ { device = "/swapfile"; size = 2048; } ];

  # use a nested array for defining your services, as vim indent will make it
  # a lot easier to navigate as you collapse/expand blocks.

  services = {

    # this will configure this host as a zookeeper node and mesos-master,
    # deploying all the required services.
    clusterMM = {
      enable = true;
      tinc_ip_address = "${d.my.tinc_ip_address}";
      tinc_domain = "${d.my.tinc_domain}";
      tinc_interface = "${d.my.tinc_interface}";
      tinc_hostname = "${d.my.tinc_hostname}";
      tinc_public_key = "${d.my.tinc_public_key}";
      tinc_private_key = "${d.my.tinc_private_key}";
      tinc_compression = "${d.common.tinc_compression}";
      zk_string = "${d.common.zk_string}";
      zk_node01 = "${d.common.mesos_zk_node01}";
      zk_node02 = "${d.common.mesos_zk_node02}";
      zk_node03 = "${d.common.mesos_zk_node03}";
      zookeeper_id = d.my.zookeeper_id;
      dns_resolver1 = "${d.common.mesos_dns_resolver1}";
      dns_resolver2 = "${d.common.mesos_dns_resolver2}";
    };
    dbus.enable    = true;
  };
}
