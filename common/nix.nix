{ nix, ... }:

{
  nix.maxJobs = 1;
  nix.useSandbox = true;
  nix.daemonNiceLevel = 19;
  nix.gc.automatic = true;
  nix.gc.dates = "03:15";
  nix.extraOptions = ''
    build-cores = 1
  '';

  # use a http url, so that we can squid it up
  nix.binaryCaches = [
    "http://nixos.org/binary-cache"
  ];
}