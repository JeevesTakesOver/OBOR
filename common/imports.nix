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
  ];

  system.stateVersion = "16.09";

}
