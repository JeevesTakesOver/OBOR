#!/usr/bin/env bash
sudo rm -rf /old-root
sudo rm -rf /tmp-nixos
sudo rm -f /etc/nixos/result
which git || sudo nix-env -i git
test -e /nixpkgs || sudo git clone https://github.com/Azulinho/mynixpkgs.git /nixpkgs
cd /nixpkgs && sudo git pull && sudo git checkout local_release_1703
cd /tmp
which wget || sudo nix-env -i wget
sudo wget -q --no-check-certificate -c --header='Cookie: oraclelicense=accept-securebackup-cookie' http://download.oracle.com/otn-pub/java/jdk/8u111-b14/jdk-8u111-linux-x64.tar.gz || echo
sudo nix-store --add-fixed sha256 jdk-8u111-linux-x64.tar.gz

sudo wget -q --no-check-certificate -c --header='Cookie: oraclelicense=accept-securebackup-cookie' http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jdk-8u121-linux-x64.tar.gz || echo
sudo nix-store --add-fixed sha256 jdk-8u121-linux-x64.tar.gz

sudo wget -q --no-check-certificate -c --header='Cookie: oraclelicense=accept-securebackup-cookie' http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz || echo
sudo nix-store --add-fixed sha256 jdk-8u131-linux-x64.tar.gz


if [ -e /swapfile ]; then
    sudo swapon /swapfile
else
    sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
    sudo mkswap /swapfile
    sudo swapon /swapfile
fi

set -e
sudo nixos-rebuild build  -I nixpkgs=/nixpkgs/
sudo nixos-rebuild switch  -I nixpkgs=/nixpkgs/
sudo nix-collect-garbage -d

set +e
sudo swapoff /swapfile
sudo rm -f /swapfile

