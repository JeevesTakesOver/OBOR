{ services, pkgs, programs, environment, networking, virtualisation, config, 
  lib, time, ... }:

let 
  cfg = config.services.clusterMS;
in

with lib;
  
{
  options = {
    services.clusterMS = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = "Defines this node as a mesos-master node";
      };

      tinc_ip_address = mkOption {
        default = "";
        type = with types; str;
        description = "The Tinc VPN IP address";
      };

      tinc_domain = mkOption {
        default = "";
        type = with types; str;
        description = "The Tinc DNS domain";
      };

      tinc_interface = mkOption {
        default = "";
        type = with types; str;
        description = "The Tinc network interface";
      };

      tinc_hostname = mkOption {
        default = "";
        type = with types; str;
        description = "The Tinc hostname (using '_')";
      };

      tinc_compression = mkOption {
        default = "";
        type = with types; str;
        description = "The Tinc networks compression to use";
      };

      tinc_public_key = mkOption {
        default = "";
        type = with types; str;
        description = "The Tinc public key";
      };

      tinc_private_key = mkOption {
        default = "";
        type = with types; str;
        description = "The Tinc private key";
      };

      zk_string = mkOption {
        default = "";
        type = with types; str;
        description = "The Zookeeper string";
      };

      zk_node01 = mkOption {
        default = "";
        type = with types; str;
        description = "The Zookeeper node01 address";
      };

      zk_node02 = mkOption {
        default = "";
        type = with types; str;
        description = "The Zookeeper node02 address";
      };

      zk_node03 = mkOption {
        default = "";
        type = with types; str;
        description = "The Zookeeper node03 address";
      };

      zookeeper_id = mkOption {
        type = with types; int;
        description = "The Zookeeper id";
      };

      dns_resolver1 = mkOption {
        default = "";
        type = with types; str;
        description = "DNS nameserver (typically the zk/mesos master nodes)";
      };

      dns_resolver2 = mkOption {
        default = "";
        type = with types; str;
        description = "DNS nameserver (typically the zk/mesos master nodes)";
      };

      dns_resolver3 = mkOption {
        default = "";
        type = with types; str;
        description = "DNS nameserver (typically the zk/mesos master nodes)";
      };

      dockerStorageDriver = mkOption {
        default = "overlay2"; 
        type = with types; str;
        description = "Docker storage driver to use ('overlay2')";
      };

      timezone = mkOption {
        default = "GMT"; 
        type = with types; str;
        description = "Timezone for all our hosts";
      };

      workDir = mkOption {
        default = "/var/lib/mesos"; 
        type = with types; str;
        description = "Mesos workdir";
      };

      mesosUser = mkOption {
        default = "mesos"; 
        type = with types; str;
        description = "Mesos user";
      };

    };
  }; # close options


  config = mkIf cfg.enable {
    # don't start the ssh-agent #
    programs.ssh.startAgent = false;

    # use a nested array for defining your services, as vim indent will make it
    # a lot easier to navigate as you collapse/expand blocks.

    services = {

      mesos.slave = {
        enable = true;
        master = "${cfg.zk_string}";
        ip = "${cfg.tinc_ip_address}";
        workDir = "${cfg.workDir}";
        mesosUser = "${cfg.mesosUser}";
        # mesos can be VERY verbose
        logLevel = "WARNING";
        extraCmdLineOptions = [
          "--log_dir=/var/log/mesos-slave"
          "--hostname=${config.networking.hostName}.${cfg.tinc_domain}"
          "--containerizers=docker,mesos"
          "--switch_user"
        ];
      }; # close mesos-slave

      consul = {
        enable = true;
        webUi = true;
        forceIpv4 = true;
        interface = {
          advertise = "${cfg.tinc_interface}";
          bind = "${cfg.tinc_interface}";
        };
        alerts = {
          listenAddr = "${cfg.tinc_ip_address}:9000";
          consulAddr = "${cfg.tinc_ip_address}:8500";
        };
      }; # close consul


      logstash = {
        address = "$cfg.tinc_ip_address}";
      }; # close logstash


      tinc = {
        networks = {
          core-vpn = {
            name = "${cfg.tinc_hostname}";
            hosts = {
              "${cfg.tinc_hostname}" = ''
                Name=${cfg.tinc_hostname}
                Port=655
                Compression=${cfg.tinc_compression}

                ${cfg.tinc_public_key}

              '';
            }; # close hosts block
          }; # close core-vpn block
        }; # close networks block
      }; # close tinc block

    }; # close services block

    environment = {
      etc = {
        "tinc/core-vpn/rsa_key.priv" = { 
          mode = "0600";
          text = ''
            ${ cfg.tinc_private_key }
          '';
        }; # close tinc/core-vpn/rsa_key.priv block

        "tinc/core-vpn/rsa_key.pub" = {
          mode = "0644";
          text = ''
            ${cfg.tinc_public_key}
          '';
        }; # close tinc/core-vpn/rsa_key.pub block

        # attempt to use gethostname() so that this block could be moved
        # to the common section.
        "tinc/core-vpn/dhclient.conf" = {
          mode = "0644";
          text = ''
            option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;

            # https://bugs.launchpad.net/ubuntu/+source/isc-dhcp/+bug/1006937
            send host-name = "${config.networking.hostName}";
            send dhcp-requested-address ${cfg.tinc_ip_address};

            request subnet-mask, broadcast-address, time-offset, routers,
                domain-name, domain-search, host-name,
                netbios-name-servers, netbios-scope, interface-mtu,
                rfc3442-classless-static-routes, ntp-servers;

            timeout 300;
          '';
        }; #close tinc/core-vpn/dhclient.conf block

      }; # close etc block
    }; # close environment block

    virtualisation = {
      docker = {
        storageDriver = "${cfg.dockerStorageDriver}";
        extraOptions = "--ip ${cfg.tinc_ip_address }";
      }; # close docker

      # enable libvirtd
      libvirtd.enable = true;

      # enable virtualbox
      virtualbox.host.enable = true;
    }; # close virtualisation


    time = {
      timeZone = "${cfg.timezone}"; # make sure all logging agrees on a timezone
    }; # close time block

    networking = {
      # DNSmasq listens on mesos-zk-01,02,3 and probagates DNS accross the
      # different services.
      # we query the TINC based DNS servers first.
      # these may not be available at boot time
      # or during the initial provisioning of the host
      # so to avoid DNS errors, we add the Google DNS servers too.
      # requests will try every DNS server in the list
      nameservers = [ 
        "${cfg.dns_resolver1}" 
        "${cfg.dns_resolver2}" 
        "${cfg.dns_resolver3}" 
        "8.8.8.8"
        "8.8.4.4" 
        ];

      resolvconfOptions = [
        "attempts:1" 
      ];
    }; # close networking block


    # our mesos frameworks should be configured to use this user
    users.extraUsers."${cfg.mesosUser}" = {
     isNormalUser = true;
     description = "${cfg.mesosUser}";
     extraGroups = [ "vboxusers" "docker" ];
     home = "${cfg.workDir}";
     createHome = true;
     openssh.authorizedKeys.keys = [];
    }; # close users block


  }; # close module block
}

