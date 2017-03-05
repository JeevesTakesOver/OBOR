# configuration.nix
{ boot, filesystems, networking, services, ... }: 

# import our config.json settings
let 
  d = {
    common = (with builtins; fromJSON(builtins.readFile /etc/nixos/config/config.json)).common;
    # make sure we swallow the right leaf node property
    my = (with builtins; fromJSON(builtins.readFile /etc/nixos/config/config.json)).mesos_masters.node01;
  };

in {

  nixpkgs.config.allowBroken = true;

  imports = [
    ./common/imports.nix
    ./pkgs.nix
    /etc/nixos/common/mesos-master-services.nix
  ];

  networking = {
    hostName = "${d.my.hostname}";

    interfaces."${d.my.public_interface}" = {
      ip4 = [ 
        { address = "${d.my.public_ip_address}"; 
        prefixLength = d.my.public_ip_netmask; } 
      ];
    };

    # we don't actually need to set the default GW on vagrant boxes
    # as this is done by the NAT interface
    # defaultGateway = "${d.my.default_gateway}";

    # and update /etc/hosts
    extraHosts = ''
      ${d.my.public_ip_address} ${d.my.hostname} ${d.my.public_fqdn}
      ${d.common.etc_hosts_entries}
    '';
  };

  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [ "ata_piix" ];
    # Creates a "vagrant" users with password-less sudo access
  users = {
    extraGroups = [ { name = "vagrant"; } { name = "vboxsf"; } ];
    extraUsers  = [ {
      description     = "Vagrant User";
      name            = "vagrant";
      group           = "vagrant";
      extraGroups     = [ "users" "vboxsf" "wheel" ];
      password        = "vagrant";
      home            = "/home/vagrant";
      createHome      = true;
      useDefaultShell = true;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
      ];
    } ];
  };

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


  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };

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

    virtualbox.enable = true;
    dbus.enable    = true;

  };



}
