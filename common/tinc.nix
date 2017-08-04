{ services, pkgs, environment,... }:

# import our config.json settings
let 
  d = {
    common = (with builtins; fromJSON(builtins.readFile /etc/nixos/config/config.json)).common;
    # make sure we swallow the right leaf node property
    my = (with builtins; fromJSON(builtins.readFile /etc/nixos/config/config.json)).mesos_masters.node01;
  };

in {
  services.avahi.enable = false;
  services.avahi.ipv4 = false;
  services.avahi.ipv6 = false;
  services.avahi.nssmdns = true;
  services.avahi.publish.enable = false;
  services.avahi.publish.addresses = false;
  # make sure we use avahi services on the tinc.core-vpn interface
  # services.avahi.interfaces = [ "tinc.core-vpn" ];

  services.tinc.networks.core-vpn.debugLevel = 2;
  services.tinc.networks.core-vpn.interfaceType = "tap";
  services.tinc.networks.core-vpn.chroot=false; # disable as we need to run tinc-up
  services.tinc.networks.core-vpn.package=pkgs.tinc;
  services.tinc.networks.core-vpn.extraConfig = ''
      AddressFamily = ipv4
      LocalDiscovery = yes
      Mode=switch
      ConnectTo = core_network_01
      ConnectTo = core_network_02
      ConnectTo = core_network_03
      Cipher=aes-256-cbc
      AutoConnect = yes
      Forwarding = kernel
      ProcessPriority = high
      TCPOnly = yes
    '';

  services.tinc.networks.core-vpn.hosts.core_network_01 = ''
    Name=core_network_01
    Address=${d.common.tinc_core_node01_fqdn}
    Port=655
    Compression=${d.common.tinc_compression}
    Subnet=${d.common.tinc_core_node01_tinc_ip_address}/32

    ${d.common.tinc_core_node01_public_key}
  '';

  services.tinc.networks.core-vpn.hosts.core_network_02 = ''
    Name=core_network_02
    Address=${d.common.tinc_core_node02_fqdn}
    Port=655
    Compression=${d.common.tinc_compression}
    Subnet=${d.common.tinc_core_node02_tinc_ip_address}/32

    ${d.common.tinc_core_node02_public_key}
  '';

  services.tinc.networks.core-vpn.hosts.core_network_03 = ''
    Name=core_network_03
    Address=${d.common.tinc_core_node03_fqdn}
    Port=655
    Compression=${d.common.tinc_compression}
    Subnet=${d.common.tinc_core_node03_tinc_ip_address}/32

    ${d.common.tinc_core_node03_public_key}
  '';

  environment.etc."tinc/core-vpn/tinc-up".mode = "0755";
  environment.etc."tinc/core-vpn/tinc-up".text = ''
   #!/bin/sh
   PATH=/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH

  # see: https://www.tinc-vpn.org/pipermail/tinc/2017-January/004729.html
  macfile=/etc/tinc/$NETNAME/address
  if [ -f $macfile ]; then
        ip link set $INTERFACE address `cat $macfile`
  else
        cat /sys/class/net/$INTERFACE/address >$macfile
  fi

   #avahi-autoipd -D $INTERFACE -t /etc/tinc/core-vpn/tinc-avahi-autoipd -w
   # https://bugs.launchpad.net/ubuntu/+source/isc-dhcp/+bug/1006937
   dhclient -4 -nw -v $INTERFACE -cf /etc/tinc/core-vpn/dhclient.conf -r
   dhclient -4 -nw -v $INTERFACE -cf /etc/tinc/core-vpn/dhclient.conf

   # TODO: we're assuming a 169.254.0.0 block here, fix it
   # reset VPN route to only send 169.254.0.0 traffic
   nohup /etc/tinc/core-vpn/fix-route >/dev/null 2>&1 &
    '';

   environment.etc."tinc/core-vpn/tinc-down".mode = "0755";
   environment.etc."tinc/core-vpn/tinc-down".text = ''
    #!/bin/sh
    PATH=/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH

    dhclient -4 -nw -v $INTERFACE -cf /etc/tinc/core-vpn/dhclient.conf -r
    '';

   environment.etc."tinc/core-vpn/tinc-avahi-autoipd".mode = "0755";
   environment.etc."tinc/core-vpn/tinc-avahi-autoipd".text = ''
    #!/bin/sh
    set -e
    PATH=/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH
    # Command line arguments:
    #   $1 event that happened:
    #          BIND:     Successfully claimed address
    #          CONFLICT: An IP address conflict happened
    #          UNBIND:   The IP address is no longer needed
    #          STOP:     The daemon is terminating
    #   $2 interface name
    #   $3 IP adddress

    # Use a different metric for each interface, so that we can set
    # identical routes to multiple interfaces.

    METRIC=$((1000 + `cat "/sys/class/net/$2/ifindex" 2>/dev/null || echo 0`))

    # we don't set a label due to:
    # https://bugs.centos.org/view.php?id=11293
    case "$1" in
        BIND)
            ip addr add "$3"/16 brd 169.254.255.255  scope link dev "$2"
            ip route add default dev "$2" metric "$METRIC" scope link ||:
            ;;

        CONFLICT|UNBIND|STOP)
            ip route del default dev "$2" metric "$METRIC" scope link ||:
            ip addr del "$3"/16 brd 169.254.255.255 scope link dev "$2"
            ;;

        *)
            echo "Unknown event $1" >&2
            exit 1
            ;;
    esac
    '';

  environment.etc."tinc/core-vpn/fix-route".mode = "0755";
  environment.etc."tinc/core-vpn/fix-route".text = ''
    #!/usr/bin/env bash

    sleep 15
    # TODO: we're assuming a 169.254.0.0 block here, fix it
    netstat -rnv | grep 169.254.0.0 | grep 0.0.0.0 >/dev/null 2>&1

    if [ $? = 0 ]; then
      # TODO: we're assuming a 169.254.0.0 block here, fix it
      route del -net 169.254.0.0 netmask 255.255.0.0 gateway 0.0.0.0
      route add -net 169.254.0.0 netmask 255.255.0.0 gateway `ifconfig tinc.core-vpn| grep inet | awk '{ print $2 }' `
    fi
    '';


}
