{ config, lib, pkgs, environment, virtualisation,  ... }:

with lib;

let

  cfg = config.services.OBORmesos-consul;

in {

  ###### interface

  options.services.OBORmesos-consul = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
	Whether to enable the marathon mesos LB.
      '';
    };

    zkConnectionString = mkOption {
      type = types.str;
      default = "zk://leader.mesos:2181/mesos";
      description = ''
	ZK connection string
      '';
    };

  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.OBORmesos-consul = {
      description = "OBORmesos-consul Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "OBORzookeeper.service" "OBORmesos-master.service" "OBORmesos-slave.service" "OBORmarathon.service" "docker.service" ];

      serviceConfig = {
        ExecStart = "${pkgs.docker}/bin/docker run --net=host ciscocloud/mesos-consul:v0.4.0 --mesos-ip-order=mesos,host --zk=${ cfg.zkConnectionString } ";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
