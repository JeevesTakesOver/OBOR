{ services, pkgs, programs, environment, networking, virtualisation, config, 
  lib, time, ... }:

let 
  cfg = config.services.clusterMS;
in

with lib;
  
{
  imports = [
  ./services/OBORmesos-master.nix
  ./services/OBORmesos-slave.nix
  ./services/OBORtinc.nix
  ./services/OBORzookeeper.nix
  ./services/OBORmesos-dns.nix
  ./services/OBORmarathon.nix
  ./services/OBORmarathon-lb.nix
  ./obor-watchdog.nix
];

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

      tinc_core_node01_fqdn = mkOption {
        description = "public IP address for Railtrack Core node 01";
        type = types.str;
      };

      tinc_core_node01_ip_address = mkOption {
        description = "tinc IP address for Railtrack Core node 01";
        type = types.str;
      };

      tinc_core_node01_public_key = mkOption {
        description = "tinc public key for Railtrack Core node 01";
        type = types.str;
      };


      tinc_core_node02_fqdn = mkOption {
        description = "public IP address for Railtrack Core node 02";
        type = types.str;
      };

      tinc_core_node02_ip_address = mkOption {
        description = "tinc IP address for Railtrack Core node 02";
        type = types.str;
      };

      tinc_core_node02_public_key = mkOption {
        description = "tinc public key for Railtrack Core node 02";
        type = types.str;
      };

      tinc_core_node03_fqdn = mkOption {
        description = "public IP address for Railtrack Core node 03";
        type = types.str;
      };

      tinc_core_node03_ip_address = mkOption {
        description = "tinc IP address for Railtrack Core node 03";
        type = types.str;
      };

      tinc_core_node03_public_key = mkOption {
        description = "tinc public key for Railtrack Core node 03";
        type = types.str;
      };

      tinc_network = mkOption {
        description = "Tinc network name";
        type = types.str;
      };

      tinc_network_netmask = mkOption {
        description = "Tinc network netmastk";
        type = types.str;
      };


    };



  }; # close options


  config = mkIf cfg.enable {
    # don't start the ssh-agent #
    programs.ssh.startAgent = false;

    # use a nested array for defining your services, as vim indent will make it
    # a lot easier to navigate as you collapse/expand blocks.

    services = {

      OBORmarathon-lb = {
        enable = true;
        extraCmdLineOptions = [
          "sse" 
          "--group external"
          "--marathon http://leader.mesos:8080" 
          "--haproxy-map" 
        ];
      }; # close marathon-lb block

      OBORmesos.slave = {
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
          "--switch_user"
        ];
      }; # close mesos-slave

      logstash = {
        listenAddress = "$cfg.tinc_ip_address}";
      }; # close logstash


      OBORtinc = {
        networks = {
          "${cfg.tinc_network}" = {
            name = "${cfg.tinc_hostname}";
            tinc_network_netmask = "${cfg.tinc_network_netmask}";
            tinc_interface = "${cfg.tinc_interface}";
            tinc_ip_address = "${cfg.tinc_ip_address}";
            tinc_private_key = "${cfg.tinc_private_key}";
            tinc_public_key = "${cfg.tinc_public_key}";
	          debugLevel = 2;
	          interfaceType = "tap";
	          chroot=false; # disable as we need to run tinc-up
	          package=pkgs.tinc;
	          extraConfig = ''
		          AddressFamily = ipv4
		          LocalDiscovery = yes
		          Mode=switch
		          ConnectTo = core_network_01
		          ConnectTo = core_network_02
		          ConnectTo = core_network_03
		          Cipher=aes-256-cbc
		          ProcessPriority = high
	          '';

            hosts = {
              "${cfg.tinc_hostname}" = ''
                Name=${cfg.tinc_hostname}
                Port=655
                Compression=${cfg.tinc_compression}

                ${cfg.tinc_public_key}

              '';

		          core_network_01 = ''
		            Name=core_network_01
		            Address=${cfg.tinc_core_node01_fqdn}
		            Port=655
		            Compression=${cfg.tinc_compression}
		            Subnet=${cfg.tinc_core_node01_ip_address}/32

		            ${cfg.tinc_core_node01_public_key}

		          '';

		          core_network_02 = ''
		            Name=core_network_02
		            Address=${cfg.tinc_core_node02_fqdn}
		            Port=655
		            Compression=${cfg.tinc_compression}
		            Subnet=${cfg.tinc_core_node02_ip_address}/32

		            ${cfg.tinc_core_node02_public_key}

		          '';

		          core_network_03 = ''
		            Name=core_network_03
		            Address=${cfg.tinc_core_node03_fqdn}
		            Port=655
		            Compression=${cfg.tinc_compression}
		            Subnet=${cfg.tinc_core_node03_ip_address}/32

		            ${cfg.tinc_core_node03_public_key}

		          '';
            }; # close hosts block
          }; # close core-vpn block
        }; # close networks block
      }; # close tinc block




      # enable the obor-watchdog
      obor-watchdog =  {
        enable = true;
        monitor_block = ''
            #!/run/current-system/sw/bin/bash
            export PATH=$PATH:/run/current-system/sw/bin/:/run/wrappers/bin/

            function retry {
              local retry_max=$1
              shift

              local count=$retry_max
              while [ $count -gt 0 ]; do
                "$@" && break
                count=$(($count - 1))
                sleep 1
              done

              [ $count -eq 0 ] && {
                return 1
              }
              return 0
            }

            function tinc_ip_address() {
              ifconfig tinc.core-vpn | grep -E  'inet [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.*netmask' | awk '{ print $2 }' | head -1 | tr -d "\n"
            }

            function check_tinc_vpn() {
              ping -c 1 `tinc_ip_address` >/dev/null 2>&1
              return $?
            }

            function check_dockerd() {
              timeout 20 docker ps >/dev/null 2>&1
              return $?
            }

            function check_traefik() {
              netstat -nltp | grep '.*:80 .*/docker-proxy' > /dev/null 2>&1
              return $?
            }

            function check_marathon_lb() {
              netstat -nltp | grep '.*:443 .*/haproxy' > /dev/null 2>&1
              return $?
            }

            while true; do
              retry 5 check_marathon_lb || (systemctl restart OBORmarathon-lb ; logger -t obor-watchdog 'restarting OBORmarathon-lb')
              retry 5 check_tinc_vpn || (systemctl restart tinc.core-vpn;  logger -t obor-watchdog 'restarting tinc.core-vpn')
              retry 5 check_dockerd || (systemctl restart docker;  logger -t obor-watchdog 'restarting docker')
              retry 5 check_traefik || (systemctl restart OBORtraefik ; logger -t obor-watchdog 'restarting OBORtraefik')

              sleep 60
            done
        '';
      };

    }; # close services block

    virtualisation = {
      docker = {
        storageDriver = "${cfg.dockerStorageDriver}";
        extraOptions = "--ip ${cfg.tinc_ip_address }";
      }; # close docker
    }; # close virtualisation




    time = {
      timeZone = "${cfg.timezone}"; # make sure all logging agrees on a timezone
    }; # close time block

    # our mesos frameworks should be configured to use this user
    users.extraUsers."${cfg.mesosUser}" = {
     isNormalUser = true;
     description = "${cfg.mesosUser}";
     extraGroups = [ "vboxusers" "docker" "wheel"];
     home = "${cfg.workDir}";
     createHome = true;
     openssh.authorizedKeys.keys = [];
    }; # close users block

    # desperate attempt to stop resolvconf from updating /etc/resolv.conf
    environment.etc."resolvconf.conf" = {
      mode = "0644";
      text = ''
        resolv_conf=/etc/resolv.conf.disabled
      '';
    };

    # now we can set our own /etc/resolv.conf
    # DNSmasq listens on mesos-zk-01,02,3 and probagates DNS accross the
    # different services.
    # these may not be available at boot time
    # or during the initial provisioning of the host
    # so to avoid DNS errors, we add the Google DNS servers too.
    # requests will try every DNS server in the list
    environment.etc."resolv.conf" = {
      mode = "0644";
      text = ''
        search ${cfg.tinc_domain}
        nameserver ${cfg.dns_resolver1}
        nameserver ${cfg.dns_resolver2} 
        nameserver 8.8.8.8
        options attempts:1
        options timeout:1
      '';
    };
  }; # close module block
}


