{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.obor-watchdog;

  watchdogScript = pkgs.writeScriptBin "obor-watchdog" ''
    ${ cfg.monitor_block }
  '';
in
  
{

  options.services.obor-watchdog = {

      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Whenever to enable the obor-watchdog";
      };

      monitor_block = mkOption {
        default = "";
        type = types.lines;
        description = "watchdog monitor script block";
      };
    };

  config = mkIf cfg.enable {

    systemd.services.obor-watchdog = {
      description = "obor-watchdog server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = 5;
        KillMode = "process";

        ExecStart = "${watchdogScript}/bin/obor-watchdog";
      };


    };
  };

}
