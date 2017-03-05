{ pkgs, nixpkgs, ... }:

{
  nixpkgs.config = {

    allowUnfree = true;
  };
}
