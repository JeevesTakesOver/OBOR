{ pkgs, stdenv, fetchurl, wget, xz, bzip2, linuxPackagesFor
, recurseIntoAttrs }:
let
  myCkPatch = stdenv.mkDerivation {
    name = "ck-patch-4.8-ck8";
    src = fetchurl {
      url = "http://ck.kolivas.org/patches/4.0/4.8/4.8-ck8/patch-4.8-ck8.xz";
      sha256 = "cea596c606da2125946154a0121ea0516583f659ad823c93669ad5d25bbc3ef7";
    };
    phases = [ "installPhase" ];
    installPhase = "${xz.bin}/bin/xzcat $src > $out";
  };
  myBfqPatch = stdenv.mkDerivation {
    name = "bfq-patch-4.4.0-v7r11";
    phases = [ "installPhase" ];
    impureEnvVars = [ "http_proxy" "https_proxy" ];
    installPhase = ''
      rev="4.8.0-v8r4"
      ${wget}/bin/wget --quiet --no-directories --no-parent \
        --recursive --level 1 --reject "*.html*" --accept "*.patch" \
        "http://algogroup.unimore.it/people/paolo/disk_sched/patches/$rev/"
      cat *.patch > $out
    '';
    outputHashAlgo = "sha256";
    outputHash = "1gdm1vlklcsi5lq752dg905nl2bjcgfrx1qvj21sx8w45ipwfjq2";
  };
  myKernel = pkgs.linuxPackages_4_8.override {
    kernelPatches = [
      { name = "ck";     patch = myCkPatch; }
      { name = "bfq";    patch = myBfqPatch; }
    ];
    extraConfig = ''
      IOSCHED_BFQ y
      DEFAULT_BFQ y
      RCU_TORTURE_TEST? n
      SCHED_AUTOGROUP? n
    '';
      # TODO:
      #USB_G_DBGP m
      #USB_G_DBGP_SERIAL y
  };
  myPackages = linuxPackagesFor myKernel myPackages;
in recurseIntoAttrs myPackages

