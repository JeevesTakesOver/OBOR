{ config, lib, pkgs, environment, virtualisation,  ... }:

with lib;

let

  cfg = config.services.OBORtraefik;

in {

  ###### interface

  options.services.OBORtraefik = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
	Whether to enable the traefik LB.
      '';
    };

    extraCmdLineOptions = mkOption {
      type = types.str;
      default = "--consulcatalog.endpoint=localhost:8500";
      description = ''
	Extra command line options to pass to traefik.
      '';
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.OBORtraefik = {
      description = "OBORtraefik Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "consul.service" ];

      serviceConfig = {
        ExecStart = "${pkgs.docker}/bin/docker run --rm -p 80:80 traefik:1.6-alpine ${ cfg.extraCmdLineOptions } ";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
