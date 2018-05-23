{ config, pkgs, ... }:
{
  networking.interfaces = [
    { 
      name         = "enp0s8";
      ipAddress    = "192.168.56.202";
      prefixLength = 24;
    }
  ];
}
