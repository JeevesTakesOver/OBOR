{ config, lib, pkgs, environment, virtualisation,  ... }:

with lib;

let

  cfg = config.services.OBORconsul;

in {

  ###### interface

  options.services.OBORconsul = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
	Whether to enable the Consul agent
      '';
    };

    consulAgentFlags = mkOption {
      type = types.str;
      default = "";
      description = ''
	Consul agent flags
      '';
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.OBORconsul = {
      description = "OBORconsul Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "docker.service" ];

      serviceConfig = {
        ExecStart = "${pkgs.docker}/bin/docker run --rm --net=host -v /var/lib/consul:/consul/data consul:1.0.7 agent ${ cfg.consulAgentFlags } ";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
