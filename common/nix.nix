{ nix, ... }:

{
  nix.maxJobs = 8;
  nix.useSandbox = true;
  nix.daemonNiceLevel = 19;
  # we cleanup through our update.sh script
  # nix.gc.automatic = false;
  # nix.gc.dates = "03:15";
  nix.extraOptions = ''
    build-cores = 4
    gc-keep-outputs = true
  '';

  # use a http url, so that we can squid it up
  nix.binaryCaches = [
    "http://nixos.org/binary-cache"
  ];
}
