# clusterMM.nix
{ services, pkgs, programs, environment, networking, virtualisation, config,
  lib, time, boot, ... }:

let
  cfg = config.services.clusterMM;
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
  ./services/OBORconsul.nix
  ./obor-watchdog.nix
  ];

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

      tinc_compression = mkOption {
        description = "Tinc Compression";
        default = "6";
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

      syslog_endpoint = mkOption {
        description = "Syslog aggregator box";
        type = types.str;
        default = "@@syslog.marathon.mesos:514";
      };

      consul_other_node = mkOption {
        description = "a second consul node";
        type = types.str;
      };
    };
  }; # close options


  config = mkIf cfg.enable {
    # don't start the ssh-agent #
    programs.ssh.startAgent = false;

    # use a nested array for defining your services, as vim indent will make it
    # a lot easier to navigate as you collapse/expand blocks.

    boot.kernelParams = [ "systemd.journald.forward_to_syslog" ] ;

    services = {

      cron = {
        enable = true;
        systemCronJobs = [
          "0 {cfg.zookeeper_id} * * * root systemctl restart OBORmarathon"
          "0 1{cfg.zookeeper_id} * * * root systemctl restart OBORmarathon"
          "0 {cfg.zookeeper_id} * * * root systemctl restart OBORmesos-master"
          "0 1{cfg.zookeeper_id} * * * root systemctl restart OBORmesos-master"
          "0 {cfg.zookeeper_id} * * * root systemctl restart OBORzookeeper"
          "0 1{cfg.zookeeper_id} * * * root systemctl restart OBORzookeeper"
        ];
      };

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
        advertiseIp = "${cfg.tinc_ip_address}";
        extraCmdLineOptions = [
          "--hostname=${config.networking.hostName}.${cfg.tinc_domain}"
          "--log_dir=/var/log/mesos-master"
          "--max_completed_frameworks=10"
          "--max_completed_tasks_per_framework=50"
          "--max_unreachable_tasks_per_framework=50"
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
          "--enable_features" "task_killing"
          "--task_lost_expunge_initial_delay" "120000"
          "--task_lost_expunge_interval" "300000"
          "--failover_timeout" "180"
          "--mesos_user" "mesos"
          "--zk_max_versions" "5"
          "--zk_session_timeout" "30000"
          "--mesos_heartbeat_interval" "30000"
        ];
      }; # close marathon

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

          # read /etc/hosts.masters.kubernetes and set a RR rule
          # to point to masters.kubernetes to our 3 master nodes
          addn-hosts=/etc/hosts.masters.kubernetes

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

      logstash = {
        listenAddress = "${cfg.tinc_ip_address}";
      }; # close logstash block

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

            # NOTE: only etcd is enabled, as it is required for bootstrapping

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
              timeout 5 host www.google.com > /dev/null 2>&1
              return $?
            }

            function check_mesos_dns() {
              timeout 5 host leader.mesos > /dev/null 2>&1
              return $?
            }

            function check_mesos() {
              ip=`tinc_ip_address`
              curl -s -L http://$ip:5050/state > /dev/null 2>&1
              return $?
            }

            function check_consul() {
              netstat -nltp | grep '.*:8300 .*/consul' > /dev/null 2>&1
              return $?
            }

            function check_etcd() {
              netstat -nltp | grep '.*:2379 .*/etcd' > /dev/null 2>&1
              return $?
            }

            while true
            do
              retry 5 check_etcd || (systemctl restart etcd ; logger -t obor-watchdog 'restarting etcd')

              sleep 60
            done
        '';
      };

      journald.extraConfig = ''
        ForwardToSyslog=true;
        Storage=None;
      '';


      rsyslogd.enable = true;
      rsyslogd.defaultConfig = "";
      rsyslogd.extraConfig = ''
        $ModLoad imuxsock
        $OmitLocalLogging off
        $SystemLogSocketName /run/systemd/journal/syslog

        # setting escaping off to make it possible to remove the control characters
        $EscapeControlCharactersOnReceive off

        # removing the optimization from use (it slows things down)
        $OptimizeForUniprocessor on

        # Using queue for 20000 messages. After that the messages are dropped instantly
        $MainMsgQueueSize 20000
        $MainMsgQueueDiscardMark 20000
        $MainMsgQueueTimeoutEnqueue 0

        *.* ${cfg.syslog_endpoint}
      '';

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


      vault = {
        enable = true;
        address = "${cfg.tinc_ip_address}:8200";
        storageBackend = "consul";
        storageConfig = ''
          address = "${cfg.tinc_ip_address}:8500"
          tls_disable = "true"
        '';
      }; # close vault


      # the block below should be extracted to a separate nix file
      # bootstrapping an etcd cluster requires all 3 nodes to be up
      # or the service will fail to start and timeout
      etcd.enable = true;
      etcd.name = "${cfg.tinc_ip_address}";
      etcd.listenClientUrls = ["http://${cfg.tinc_ip_address}:2379"];
      etcd.listenPeerUrls = ["http://${cfg.tinc_ip_address}:2380"];
      etcd.initialCluster = [
        "${cfg.zk_node01}=http://${cfg.zk_node01}:2380"
        "${cfg.zk_node02}=http://${cfg.zk_node02}:2380"
        "${cfg.zk_node03}=http://${cfg.zk_node03}:2380"
      ];

      kubernetes.path = [ pkgs.zfs ];
      kubernetes.roles = [ "master" ];
      kubernetes.kubelet.extraOpts = "--fail-swap-on=False";
      kubernetes.apiserver.kubeletHttps = false;
      kubernetes.addons.dashboard.enable = true;
      kubernetes.addons.dns.enable = true;
      kubernetes.apiserver.bindAddress = "0.0.0.0";
      kubernetes.apiserver.port = 8888;
      kubernetes.apiserver.securePort = 8843;
      kubernetes.apiserver.advertiseAddress = "${cfg.tinc_ip_address}";
      kubernetes.apiserver.extraOpts = " --insecure-bind-address 0.0.0.0";
      kubernetes.flannel.enable = true;
      kubernetes.etcd = {
        servers = [
          "http://${cfg.zk_node01}:2379"
          "http://${cfg.zk_node02}:2379"
          "http://${cfg.zk_node03}:2379"
        ];
      }; # close kubernetes.etcd

    }; # close services block


    virtualisation = {
      docker = {
        enable = true;
        storageDriver = "${cfg.dockerStorageDriver}";
        extraOptions = "--ip ${cfg.tinc_ip_address } --max-concurrent-downloads 1";
      }; # close docker
    }; # close virtualisation


    time = {
      timeZone = "${cfg.timezone}"; # make sure all logging agrees on a timezone
    }; # close time block

    networking = {

      # TODO: bring this into options.

      enableIPv6 = false;

      firewall.enable = true;
      firewall.allowPing = true;

      # traffic on the tin.core-vpn interface is not restricted by iptables
      firewall.trustedInterfaces = [ "tinc.core-vpn" "docker0" ];

      # allow internet/external access to ssh and tincd port.
      # ssh is required for provisioning, however it could be locked down to a
      # allow access only to a particular group of of addresses in the sshd_config
      # file
      firewall.allowedTCPPorts = [ 22 655 ];
      firewall.allowedUDPPorts = [ 655 ];

      # specify the list of primary network cards across the different boxes.
      # we need dhcpcd allocation locked down to the primary interfaces
      # as we don't want dhcpcpd to attempt to allocate ip addresses for the
      # tinc vpn interfaces.
      # locking them them ensures this won't happen
      dhcpcd.allowInterfaces = [ "enp0s3" "enp5s0" "enp0s8" "eth0"];



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

    # we map masters.kubernetes to the 3 ip addresses from our
    # master nodes
    environment.etc."hosts.masters.kubernetes" = {
      mode = "0644";
      text = ''
        ${cfg.zk_node01} masters.kubernetes
        ${cfg.zk_node02} masters.kubernetes
        ${cfg.zk_node03} masters.kubernetes
      '';
    };

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
    # we query our own dnsmasq instance first, which should query the
    # upstream core01,02 TINC dns servers.
    # these may not be available at boot time
    # or during the initial provisioning of the host
    # so to avoid DNS errors, we add the Google DNS servers too.
    # requests will try every DNS server in the list
    environment.etc."resolv.conf" = {
      mode = "0644";
      text = ''
        search ${cfg.tinc_domain}
        nameserver 127.0.0.1
        nameserver 8.8.8.8
        nameserver 8.8.4.4
        options attempts:1
        options timeout:1
      '';
    };
  }; # close module block
}
