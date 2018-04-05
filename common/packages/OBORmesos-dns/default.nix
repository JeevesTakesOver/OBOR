{ stdenv, lib, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "mesos-dns-${version}";
  version = "0.6.0";
  rev = "v${version}";
  
  goPackagePath = "github.com/mesosphere/mesos-dns";

  # Avoid including the benchmarking test helper in the output:
  subPackages = [ "." ];

  src = fetchFromGitHub {
    inherit rev;
    owner = "mesosphere";
    repo = "mesos-dns";
    sha256 = "1p7ai51hy80pmsyi5y4hspyh2965rca42wg314051y8rz05l8j00";
  };

  goDeps = ./deps.nix;
}
