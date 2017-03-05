
{ virtualisation, nixpkgs, ... }:

{

  virtualisation.docker.enable = true;
  #virtualisation.docker.extraOptions = "--iptables=false --ip-masq=false -b cbr0";
}
