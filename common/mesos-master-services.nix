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

      consul_other_node = mkOption {
        type = with types; str;
        description = "a second consul node";
      };
    };
  }; # close options


  config = mkIf cfg.enable {
    # don't start the ssh-agent #
    programs.ssh.startAgent = false;

    # use a nested array for defining your services, as vim indent will make it
    # a lot easier to navigate as you collapse/expand blocks.


    services = {


      OBORzookeeper = {
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


      OBORmesos.master = {
        enable = true;
        quorum = 2;
        zk = "${cfg.zk_string}";
        ip = "${cfg.tinc_ip_address}";
        extraCmdLineOptions = [
          "--hostname=${config.networking.hostName}.${cfg.tinc_domain}"
          "--log_dir=/var/log/mesos-master"
        ];
      }; # close mesos-master


      OBORmarathon = {
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
          "--failover_timeout" "300"
          "--mesos_user" "mesos"
        ];
      }; # close marathon

      OBORconsul = {
        enable = true;
        consulAgentFlags = " " + 
        "-server " +
        "-advertise=${cfg.tinc_ip_address} " + 
        "-bind=${cfg.tinc_ip_address} " + 
        "-client=${cfg.tinc_ip_address} " +
        "-retry-join=${cfg.consul_other_node} " + 
        "--bootstrap-expect=3";
      }; # close consul

      dnsmasq = {
        enable = true;
        resolveLocalQueries = true;
        servers = [ "8.8.8.8" "8.8.4.4" ];
        extraConfig = ''
          server=/${cfg.tinc_domain}/${cfg.dns_resolver1}
          server=/${cfg.tinc_domain}/${cfg.dns_resolver2}
          # .mesos is served by the mesos-dns listening on the tinc interface
          server=/mesos/${cfg.tinc_ip_address}#9153
          server=/consul/${cfg.tinc_ip_address}#8600
          server=/kubernetes/${cfg.tinc_ip_address}#7153
          listen-address=0.0.0.0
          bind-interfaces
          # strict-order slows down queries to tinc-core-vpn by 10ms
          # strict-order
          no-poll
          no-resolv
          no-negcache
          no-hosts
          # force our clients to always ask us
          max-ttl=1
          # and make sure our cache is never older than 30 seconds
          max-cache-ttl=30
        '';
      }; # close dnsmasq block


      OBORmesos-dns = {
        enable = true;
        config_block = ''
          {
            "zk": "${cfg.zk_string}",
            "masters": ["${cfg.zk_node01}:5050","${cfg.zk_node02}:5050", "${cfg.zk_node03}:5050"],
            "refreshSeconds": 5,
            "ttl": 5,
            "domain": "mesos",
            "port": 9153,
            "resolvers": ["${cfg.dns_resolver1}","${cfg.dns_resolver2}"],
            "timeout": 5, 
            "listener": "${cfg.tinc_ip_address}",
            "httpon": true,
            "dnson": true,
            "httpport": 8123,
            "externalon": true,
            "SOAMname": "ns1.mesos",
            "SOARname": "root.ns1.mesos",
            "SOARefresh": 60,
            "SOARetry":   600,
            "SOAExpire":  86400,
            "SOAMinttl": 60,
            "IPSources": ["mesos", "host"]
          }
        '';
      }; # close mesos-dns block

      # enable mesos-consul with default options
      OBORmesos-consul.enable = true; 

      logstash = {
        listenAddress = "${cfg.tinc_ip_address}";
      }; # close logstash block

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
              ping -c 1 `tinc_ip_address` > /dev/null 2>&1
              return $?
            }

            function check_zookeeper() {
              ip=`tinc_ip_address`
              timeout 1 echo ruok | nc $ip 2181 | grep imok > /dev/null 2>&1
              return $?
            }

            function check_marathon() {
              ip=`tinc_ip_address`
              curl -L -v http://$ip:8080 2>&1 | grep "HTTP/1.1 200 OK" > /dev/null 2>&1
              return $?
            }

            function check_dockerd() {
              timeout 20 docker ps >/dev/null 2>&1
              return $?
            }

            function check_dnsmasq() {
              timeout 5 nslookup www.google.com > /dev/null 2>&1
              return $?
            }

            function check_mesos_dns() {
              timeout 5 nslookup leader.mesos > /dev/null 2>&1
              return $?
            }

            function check_consul() {
              netstat -nltp | grep '.*:8300 .*/consul' > /dev/null 2>&1
              return $?
            }

            function check_mesos_consul() {
              docker ps | grep mesos-consul | grep Up> /dev/null 2>&1
              return $?
            }

            function check_mesos() {
              ip=`tinc_ip_address`
              curl -s -L http://$ip:5050/state > /dev/null 2>&1
              return $?
            }

            while true; do
              retry 5 check_tinc_vpn || (systemctl restart OBORtinc.core-vpn; logger -t obor-watchdog 'restarting OBORtinc.core-vpn')
              retry 5 check_dockerd || (systemctl restart docker; logger -t obor-watchdog 'restarting docker')
              retry 5 check_dnsmasq || (systemctl restart dnsmasq; logger -t obor-watchdog 'restarting dnsmasq')
              retry 5 check_mesos_dns || (systemctl restart OBORmesos-dns; logger -t obor-watchdog 'restarting OBORmesos-dns')
              retry 60 check_zookeeper || (systemctl restart OBORzookeeper; logger -t obor-watchdog 'restarting OBORzookeeper')
              retry 15 check_marathon || (systemctl restart OBORmarathon; logger -t obor-watchdog 'restarting OBORmarathon')
              retry 5 check_consul || (systemctl restart OBORconsul ; logger -t obor-watchdog 'restarting OBORconsul')
              retry 5 check_mesos_consul || (systemctl restart OBORmesos-consul ; logger -t obor-watchdog 'restarting OBORmesos-consul')
              retry 5 check_mesos || (systemctl restart OBORmesos-master ; logger -t obor-watchdog 'restarting OBORmesos-master')

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
            search ${cfg.tinc_domain}
            nameserver 127.0.0.1 
            options attempts:1
            options timeout:1
            options rotate
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
        "127.0.0.1" 
        "8.8.8.8"
        "8.8.4.4" 
        ];

      resolvconfOptions = [
        "attempts:1" 
      ];
    };

  }; # close module block
}