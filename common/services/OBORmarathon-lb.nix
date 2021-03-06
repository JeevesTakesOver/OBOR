{ config, lib, pkgs, environment, virtualisation,  ... }:

with lib;

let

  cfg = config.services.OBORmarathon-lb;

in {

  ###### interface

  options.services.OBORmarathon-lb = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
	Whether to enable the marathon mesos LB.
      '';
    };

    port = mkOption {
      type = types.int;
      default = 9999;
      description = ''
	Marathon-LB listening port for HTTP connections.
      '';
    };

    extraCmdLineOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--groups=external" "--marathon http://localhost:8080" "--haproxy-map" ];
      description = ''
	Extra command line options to pass to Marathon-lb.
      '';
    };

  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.OBORmarathon-lb = {
      description = "OBORmarathon-lb Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "OBORmesos-slave.service" "docker.service" ];

      serviceConfig = {
        TimeoutStartSec = "0";
        ExecStartPre = "${pkgs.docker}/bin/docker pull mesosphere/marathon-lb:v1.12.1";
        ExecStart = "${pkgs.docker}/bin/docker run --rm -e PORTS=${ toString cfg.port } --name=marathon-lb --net=host --privileged -v /dev/log:/dev/log mesosphere/marathon-lb:v1.12.1 ${ concatStringsSep " " cfg.extraCmdLineOptions } ";
        ExecStop = "${pkgs.docker}/bin/docker kill marathon-lb";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
