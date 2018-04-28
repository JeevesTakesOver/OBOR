{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.services.OBORmesos-dns;
  OBORmesos-dns = pkgs.callPackage ../packages/OBORmesos-dns/default.nix {};

  configFile = pkgs.writeText "mesos-dns.conf" ''
  ${ cfg.config_block }
  '';

in

{

    options.services.OBORmesos-dns = {

      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Whenever to enable the mesos-dns server";
      };

      config_block = mkOption {
        default = ''
  {
    "zk": "zk://127.0.0.1:2181/mesos",
    "masters": ["127.0.0.1:5050"],
    "refreshSeconds": 60,
    "ttl": 60,
    "domain": "mesos",
    "port": 53,
    "resolvers": ["8.8.8.8", "8.8.4.4"],
    "timeout": 5, 
    "httpon": true,
    "dnson": true,
    "httpport": 8123,
    "externalon": true,
    "listener": "0.0.0.0",
    "SOAMname": "ns1.mesos",
    "SOARname": "root.ns1.mesos",
    "SOARefresh": 60,
    "SOARetry":   600,
    "SOAExpire":  86400,
    "SOAMinttl": 60,
    "IPSources": ["mesos", "host"]
  }
        '';
        type = types.lines;
        description = "config.json block";
      };
    };

  config = mkIf cfg.enable {

    systemd.services.OBORmesos-dns = {
      description = "mesos-dns server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = 5;
        KillMode = "process";

        ExecStart = "${OBORmesos-dns}/bin/mesos-dns --config ${configFile}";
      };


    };

    environment.systemPackages = [ OBORmesos-dns ];
  };

}
