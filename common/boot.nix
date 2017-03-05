{ boot, pkgs, ... }:
{


  # remove the fsck that runs at startup. It will always fail to run, stopping
  # your boot until you press *.
  boot.initrd.checkJournalingFS = false;

  boot.kernelPackages = pkgs.linuxPackages_4_8;

  boot.blacklistedKernelModules = [ "pcspkr" "snd_pcsp" ];

  boot.cleanTmpDir = true;

  # disable ipv6
  boot.kernelParams = [ "ipv6.disable=1"];

  boot.kernel.sysctl."vm.swappiness" = 10;
  boot.kernel.sysctl."vm.dirty_background_bytes" = 0;
  boot.kernel.sysctl."vm.dirty_bytes" = 0;
  boot.kernel.sysctl."vm.dirty_ratio" = 20;
  boot.kernel.sysctl."vm.dirty_background_ration" = 10;
  boot.kernel.sysctl."vm.dirty_writeback_centisecs" = 500;
  boot.kernel.sysctl."fs.aio-max-nr" = 8192;
}
