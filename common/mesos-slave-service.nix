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

      enable_virtualbox = mkOption {
        default = true;
        type = with types; bool;
        description = "Enable VirtualBox Host services?";
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
        # we query the TINC based DNS servers first.
        # these may not be available at boot time
        # or during the initial provisioning of the host
        # so to avoid DNS errors, we add the Google DNS servers too.
        # requests will try every DNS server in the list
        "resolv.conf" = {
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

      }; # close etc block
    }; # close environment block

    virtualisation = {
      docker = {
        storageDriver = "${cfg.dockerStorageDriver}";
        extraOptions = "--ip ${cfg.tinc_ip_address }";
      }; # close docker

      # enable libvirtd
      libvirtd.enable = true;


      # enable virtualbox if flag is set
      # we don't want to enable virtualbox inside a vagrant VM
      virtualbox.host.enable = 
      if cfg.enable_virtualbox then true else false;

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


  }; # close module block
}


