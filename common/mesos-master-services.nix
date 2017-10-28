{ services, pkgs, programs, environment, networking, virtualisation, config, 
  lib, time, ... }:

let 
  cfg = config.services.clusterMM;
in

with lib;
  
{
  options = {
    services.clusterMM = {
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
        description = "TINC DNS NS ip address (usually the vpn servers)";
      };

      dns_resolver2 = mkOption {
        default = "";
        type = with types; str;
        description = "TINC DNS NS ip address (usually the vpn servers)";
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
    };
  }; # close options


  config = mkIf cfg.enable {
    # don't start the ssh-agent #
    programs.ssh.startAgent = false;

    # use a nested array for defining your services, as vim indent will make it
    # a lot easier to navigate as you collapse/expand blocks.


    services = {


      zookeeper = {
        enable = true;
        id = cfg.zookeeper_id;
        servers = ''
          server.0=${cfg.zk_node01}:2888:3888
          server.1=${cfg.zk_node02}:2888:3888
          server.2=${cfg.zk_node03}:2888:3888
        '';

        extraConf =
        ''
            initLimit=10
            syncLimit=4
            tickTime=4000
            clientPortAddress=${cfg.tinc_ip_address}
        '';

        extraCmdLineOptions = [
          "-Djava.net.preferIPv4Stack=true"
          "-Dcom.sun.management.jmxremote"
          "-Dcom.sun.management.jmxremote.local.only=true"
        ];
      }; # close zookeeper


      mesos.master = {
        enable = true;
        quorum = 2;
        zk = "${cfg.zk_string}";
        ip = "${cfg.tinc_ip_address}";
        extraCmdLineOptions = [
          "--hostname=${config.networking.hostName}.${cfg.tinc_domain}"
          "--log_dir=/var/log/mesos-master"
        ];
      }; # close mesos-master


      marathon = {
        enable = true;
        zookeeperHosts = [
          "${cfg.zk_node01}:2181" 
          "${cfg.zk_node02}:2181" 
          "${cfg.zk_node03}:2181" 
        ];
        # see:
        # https://github.com/mesosphere/marathon/issues/4232#issuecomment-243443555
        # https://github.com/mesosphere/marathon/issues/4310
        extraCmdLineOptions = [ 
          "--http_address" "${cfg.tinc_ip_address}" 
          "--hostname" "${config.networking.hostName}.${cfg.tinc_domain}" 
          "--enable_features" "vips,task_killing"
          "--task_lost_expunge_gc" "180000" 
          "--task_lost_expunge_initial_delay" "120000" 
          "--task_lost_expunge_interval" "300000"
          "--failover_timeout" "600"
          "--mesos_user" "mesos"
        ];
      }; # close marathon


      marathon-lb = {
        enable = true;
        extraCmdLineOptions = [
          "sse" 
          "--group external"
          "--marathon http://${config.networking.hostName}.${cfg.tinc_domain}:8080" 
          "--haproxy-map" 
        ];
      }; # close marathon-lb block


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



      dnsmasq = {
        enable = true;
        resolveLocalQueries = true;
        servers = [ "8.8.8.8" "8.8.4.4" ];
        extraConfig = ''
          # .mesos is served by the mesos-dns listening on the tinc interface
          server=/mesos/${cfg.tinc_ip_address}#9153
          server=/kubernetes.io/${cfg.tinc_ip_address}#7153
          server=/${cfg.tinc_domain}/${cfg.dns_resolver1}
          server=/${cfg.tinc_domain}/${cfg.dns_resolver2}
          listen-address=127.0.0.1
          listen-address=${cfg.tinc_ip_address}
          bind-interfaces
          # strict-order slows down queries to tinc-core-vpn by 10ms
          # strict-order
          no-poll
          no-resolv
        '';
      }; # close dnsmasq block


      mesos-dns = {
        enable = true;
        config_block = ''
          {
            "zk": "${cfg.zk_string}",
            "masters": ["${cfg.zk_node01}:5050","${cfg.zk_node02}:5050", "${cfg.zk_node03}:5050"],
            "refreshSeconds": 60,
            "ttl": 60,
            "domain": "mesos",
            "port": 9153,
            "resolvers": ["${cfg.dns_resolver1}","${cfg.dns_resolver2}"],
            "timeout": 5, 
            "listener": "${cfg.tinc_ip_address}"
          }
        '';
      }; # close mesos-dns block


      logstash = {
        address = "${cfg.tinc_ip_address}";
      }; # close logstash block

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

      # monitor and restart tincd if we happen to not have accquired an ip
      monit = {
        enable = true;
        config = ''
          set daemon  60
          set logfile syslog facility log_daemon


          check program check-for-tinc-ip-address with path "/etc/tinc/core-vpn/check-for-tinc-ip-address"
          with timeout 5 seconds
          if status = 1 then alert
          if status = 1 for 3 cycles then exec "/run/current-system/sw/bin/systemctl restart tinc.core-vpn"

          check program check-for-docker with path "/etc/tinc/core-vpn/check-for-docker"
          with timeout 25 seconds
          if status = 1 then alert
          if status = 1 for 3 cycles then exec "/run/current-system/sw/bin/systemctl restart docker"

          check program check-for-dnsmasq with path "/etc/tinc/core-vpn/check-for-dnsmasq"
          with timeout 15 seconds
          if status = 1 then alert
          if status = 1 for 3 cycles then exec "/run/current-system/sw/bin/systemctl restart dnsmasq"

          check program check-for-mesos-dns with path "/etc/tinc/core-vpn/check-for-mesos-dns"
          with timeout 15 seconds
          if status = 1 then alert
          if status = 1 for 3 cycles then exec "/run/current-system/sw/bin/systemctl restart mesos-dns"
        '';


      };



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
            send host-name "${config.networking.hostName}";
            send dhcp-requested-address ${cfg.tinc_ip_address};

            request subnet-mask, broadcast-address, time-offset, routers,
                domain-name, domain-search, host-name,
                netbios-name-servers, netbios-scope, interface-mtu,
                rfc3442-classless-static-routes, ntp-servers;

            timeout 300;
          '';
        }; #close tinc/core-vpn/dhclient.conf block

        # desperate attempt to stop resolvconf from updating /etc/resolv.conf
        "resolvconf.conf" = {
          mode = "0644";
          text = ''
            resolv_conf=/etc/resolv.conf.disabled
          '';
        };

        # now we can set our own /etc/resolv.conf
        # DNSmasq listens on mesos-zk-01,02,3 and probagates DNS accross the
        # different services.
        # we query our own dnsmasq instance first, which should query the 
        # upstream core01,02 TINC dns servers.
        # these may not be available at boot time
        # or during the initial provisioning of the host
        # so to avoid DNS errors, we add the Google DNS servers too.
        # requests will try every DNS server in the list
        "resolv.conf" = {
          mode = "0644";
          text = ''
            nameserver ${cfg.tinc_ip_address} 
            nameserver ${cfg.dns_resolver1} 
            nameserver ${cfg.dns_resolver2} 
            nameserver 8.8.8.8
            nameserver 8.8.4.4 
            options attempts:1
            options timeout:1
            options rotate
          '';
        };

        # this is where we check if tinc got an ip address
        "tinc/core-vpn/check-for-tinc-ip-address" = {
          mode = "0755";
          text = ''
            #!/usr/bin/env bash
            set -e
            sudo ifconfig tinc.core-vpn | grep -E  'inet [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.*netmask'
          '';
        }; 

        # this is where we enable checks for docker
        "tinc/core-vpn/check-for-docker" = {
          mode = "0755";
          text = ''
            #!/usr/bin/env bash
            set -e
            timeout 20 sudo docker ps
          '';
        }; 

        # this is where we enable checks for dnsmasq
        "tinc/core-vpn/check-for-dnsmasq" = {
          mode = "0755";
          text = ''
            #!/usr/bin/env bash
            set -e
            timeout 5 nslookup www.google.com
          '';
        }; 

        # this is where we enable checks for mesos-dns
        "tinc/core-vpn/check-for-mesos-dns" = {
          mode = "0755";
          text = ''
            #!/usr/bin/env bash
            set -e
            timeout 5 nslookup leader.mesos
          '';
        }; 


      }; # close etc block
    }; # close environment block


    virtualisation = {
      docker = {
        storageDriver = "${cfg.dockerStorageDriver}";
      }; # close docker
    }; # close virtualisation


    time = {
      timeZone = "${cfg.timezone}"; # make sure all logging agrees on a timezone
    }; # close time block

    networking = {
      # DNSmasq listens on mesos-zk-01,02,3 and probagates DNS accross the
      # different services.
      # we query our own dnsmasq instance first, which should query the 
      # upstream core01,02 TINC dns servers.
      # these may not be available at boot time
      # or during the initial provisioning of the host
      # so to avoid DNS errors, we add the Google DNS servers too.
      # requests will try every DNS server in the list
      nameservers = [ 
        "${cfg.tinc_ip_address}" 
        "${cfg.dns_resolver1}" 
        "${cfg.dns_resolver2}" 
        "8.8.8.8"
        "8.8.4.4" 
        ];

      resolvconfOptions = [
        "attempts:1" 
      ];
    };

  }; # close module block
}