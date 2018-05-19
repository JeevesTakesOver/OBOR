{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.OBORtinc;

in

{

  ###### interface

  options = {

    services.OBORtinc = {

      networks = mkOption {
        default = { };
        type = types.loaOf types.optionSet;
        description = ''
          Defines the tinc networks which will be started.
          Each network invokes a different daemon.
        '';
        options = {

          extraConfig = mkOption {
            default = "";
            type = types.lines;
            description = ''
              Extra lines to add to the tinc service configuration file.
            '';
          };

          name = mkOption {
            default = null;
            type = types.nullOr types.str;
            description = ''
              The name of the node which is used as an identifier when communicating
              with the remote nodes in the mesh. If null then the hostname of the system
              is used.
            '';
          };

          ed25519PrivateKeyFile = mkOption {
            default = null;
            type = types.nullOr types.path;
            description = ''
              Path of the private ed25519 keyfile.
            '';
          };

          debugLevel = mkOption {
            default = 0;
            type = types.addCheck types.int (l: l >= 0 && l <= 5);
            description = ''
              The amount of debugging information to add to the log. 0 means little
              logging while 5 is the most logging. <command>man tincd</command> for
              more details.
            '';
          };

          hosts = mkOption {
            default = { };
            type = types.loaOf types.lines;
            description = ''
              The name of the host in the network as well as the configuration for that host.
              This name should only contain alphanumerics and underscores.
            '';
          };

          interfaceType = mkOption {
            default = "tun";
            type = types.addCheck types.str (n: n == "tun" || n == "tap");
            description = ''
              The type of virtual interface used for the network connection
            '';
          };

          listenAddress = mkOption {
            default = null;
            type = types.nullOr types.str;
            description = ''
              The ip adress to bind to.
            '';
          };

          package = mkOption {
            type = types.package;
            default = pkgs.tinc_pre;
            defaultText = "pkgs.tinc_pre";
            description = ''
              The package to use for the tinc daemon's binary.
            '';
          };

          chroot = mkOption {
            default = true;
            type = types.bool;
            description = ''
              Change process root directory to the directory where the config file is located (/etc/tinc/netname/), for added security.
              The chroot is performed after all the initialization is done, after writing pid files and opening network sockets.

              Note that tinc can't run scripts anymore (such as tinc-down or host-up), unless it is setup to be runnable inside chroot environment.
            '';
          };

          tinc_network_netmask = mkOption {
            type = types.str;
            description = "TINC Subnet mask";
          };

          tinc_broadcast_address = mkOption {
            type = types.str;
            description = "TINC Broadcast adress";
          };

          tinc_network = mkOption {
            type = types.str;
            description = "TINC network name";
          };

          tinc_interface = mkOption {
            type = types.str;
            description = "TINC network interface name";
          };

          tinc_ip_address = mkOption {
            type = types.str;
            description = "TINC ip address";
          };

          tinc_private_key = mkOption {
            type = types.str;
            description = "TINC private key";
          };

          tinc_public_key = mkOption {
            type = types.str;
            description = "TINC public key";
          };


        };
      };
    };

  };


  ###### implementation

  config = mkIf (cfg.networks != { }) {




    environment.etc = fold (a: b: a // b) { }
      (flip mapAttrsToList cfg.networks (network: data:
        flip mapAttrs' data.hosts (host: text: nameValuePair
          ("tinc/${network}/hosts/${host}")
          ({ mode = "0444"; inherit text; })
        ) // {
          "tinc/${network}/tinc.conf" = {
            mode = "0444";
            text = ''
              Name = ${if data.name == null then "$HOST" else data.name}
              DeviceType = ${data.interfaceType}
              ${optionalString (data.ed25519PrivateKeyFile != null) "Ed25519PrivateKeyFile = ${data.ed25519PrivateKeyFile}"}
              ${optionalString (data.listenAddress != null) "BindToAddress = ${data.listenAddress}"}
              Device = /dev/net/tun
              Interface = tinc.${network}
              ${data.extraConfig}
            '';
          };

    "tinc/${network}/tinc-up" = {
	mode = "0755";
        text = ''
	      #!/bin/sh
	      PATH=/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH

	      # see: https://www.tinc-vpn.org/pipermail/tinc/2017-January/004729.html
	      macfile=/etc/tinc/${network}/address
	      if [ -f $macfile ]; then
		    ip link set ${data.tinc_interface} address `cat $macfile`
	      else
		    cat /sys/class/net/${data.tinc_interface}/address >$macfile
	      fi

	      # https://bugs.launchpad.net/ubuntu/+source/isc-dhcp/+bug/1006937
	      dhclient -4 -nw -v ${data.tinc_interface} -cf /etc/tinc/${network}/dhclient.conf -r
	      dhclient -4 -nw -v ${data.tinc_interface} -cf /etc/tinc/${network}/dhclient.conf

	      nohup /etc/tinc/${network}/fix-route >/dev/null 2>&1 &
	'';
     };


    "tinc/${network}/tinc-down" = {
     	mode = "0755";
    	text = ''
	      #!/bin/sh
	      PATH=/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH

	      dhclient -4 -nw -v ${data.tinc_interface} -cf /etc/tinc/${network}/dhclient.conf -r
        '';
    };

    "tinc/${network}/fix-route" = {
         mode = "0755";
         text = ''
	      #!/usr/bin/env bash

	      sleep 15
	      netstat -rnv | grep ${network} | grep 0.0.0.0 >/dev/null 2>&1

	      if [ $? = 0 ]; then
		route del -net ${network} netmask ${data.tinc_network_netmask} gateway 0.0.0.0
		route add -net ${network} netmask ${data.tinc_network_netmask} gateway `ifconfig ${data.tinc_interface}| grep inet | awk '{ print $2 }' `
	      fi
      '';
    };








        "tinc/${network}/rsa_key.priv" = {
          mode = "0600";
          text = ''
            ${ data.tinc_private_key }
          '';
        }; # close tinc/core-vpn/rsa_key.priv block

        "tinc/${network}/rsa_key.pub" = {
          mode = "0644";
          text = ''
            ${data.tinc_public_key}
          '';
        }; # close tinc/core-vpn/rsa_key.pub block

        # attempt to use gethostname() so that this block could be moved
        # to the common section.
        "tinc/${network}/dhclient.conf" = {
          mode = "0644";
          text = ''
            option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;

            # https://bugs.launchpad.net/ubuntu/+source/isc-dhcp/+bug/1006937
            send host-name "${config.networking.hostName}";
            send dhcp-requested-address ${data.tinc_ip_address};

            request subnet-mask, broadcast-address, time-offset, routers,
                domain-name, domain-search, host-name,
                netbios-name-servers, netbios-scope, interface-mtu,
                rfc3442-classless-static-routes, ntp-servers;

            timeout 300;
          '';
        }; #close tinc/core-vpn/dhclient.conf block

        }
      ));






      networking.interfaces = flip mapAttrs' cfg.networks (network: data: nameValuePair
      ("tinc.${network}")
      ({
        name = "tinc.${network}";
        virtual = true;
        virtualType = "${data.interfaceType}";
        })
      );

    systemd.services = flip mapAttrs' cfg.networks (network: data: nameValuePair
      ("OBORtinc.${network}")
      ({
        description = "Tinc Daemon - ${network}";
        wantedBy = [ "network.target" ];
        after = [ "network-interfaces.target" ];
        path = [ data.package ];
        restartTriggers = [ config.environment.etc."tinc/${network}/tinc.conf".source ]
          ++ mapAttrsToList (host: _ : config.environment.etc."tinc/${network}/hosts/${host}".source) data.hosts;
        serviceConfig = {
          Type = "simple";
          PIDFile = "/run/tinc.${network}.pid";
          Restart = "on-failure";
          ExecStop = "/etc/tinc/${network}/tinc-down";
        };
        preStart = ''
          # To use AutoConnect = yes, we need to have rw permissions on the
          # hosts directory.
          mkdir -p /etc/tinc/${network}/hosts
          chmod 775 /etc/tinc/${network}/hosts
          chown -R tinc.${network}:nogroup /etc/tinc/${network}/hosts

          # Determine how we should generate our keys
          if type tinc >/dev/null 2>&1; then
            # Tinc 1.1+ uses the tinc helper application for key generation
          ${if data.ed25519PrivateKeyFile != null then "  # Keyfile managed by nix" else ''
            # Prefer ED25519 keys (only in 1.1+)
            [ -f "/etc/tinc/${network}/ed25519_key.priv" ] || tinc -n ${network} generate-ed25519-keys
          ''}
            # Otherwise use RSA keys
            [ -f "/etc/tinc/${network}/rsa_key.priv" ] || tinc -n ${network} generate-rsa-keys 4096
          else
            # Tinc 1.0 uses the tincd application
            [ -f "/etc/tinc/${network}/rsa_key.priv" ] || tincd -n ${network} -K 4096
          fi
        '';
        script = ''
          tincd -D -U tinc.${network} -n ${network} ${optionalString (data.chroot) "-R"} --pidfile /run/tinc.${network}.pid -d ${toString data.debugLevel}
        '';
      })
    );

    users.extraUsers = flip mapAttrs' cfg.networks (network: _:
      nameValuePair ("tinc.${network}") ({
        description = "Tinc daemon user for ${network}";
        isSystemUser = true;
      })
    );

    environment.systemPackages = [
      pkgs.tinc
      pkgs.dhcp
    ];


    };
}
