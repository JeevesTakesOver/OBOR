# common/imports.nix
{ ... }:

let 
  cluster_config = (with builtins; fromJSON(builtins.readFile ../config/config.json));
in
{
  imports = [
    ./boot.nix
    ./users.nix
    ./networking.nix
    ./internationalisation.nix
    ./nix.nix
    ./pkgs.nix
    ./security.nix
    ./services.nix
    ./tinc.nix
    ./virtualisation.nix

    ./services/OBORmesos-master.nix
    ./services/OBORmesos-slave.nix
    ./services/OBORtinc.nix
    ./services/OBORzookeeper.nix
    ./services/OBORmesos-dns.nix
    ./services/OBORmarathon.nix
    ./services/OBORmarathon-lb.nix
  ];

  system.stateVersion = "17.03";

}
