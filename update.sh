#!/run/current-system/sw/bin/bash

echo "running update.sh..."

echo "update.sh: cleaning old files..."

    sudo rm -rf /old-root
    sudo rm -rf /tmp-nixos
    sudo rm -f /etc/nixos/result

echo "update.sh: making sure openssl is installed..."
    # https://github.com/NixOS/nixpkgs/issues/3382
    openssl version >/dev/null 2>/dev/null|| sudo nix-env -Q --quiet -i openssl >/dev/null

echo "update.sh: making sure git is installed..."
    which git >/dev/null 2>&1 || sudo nix-env -Q --quiet -i git >/dev/null

echo "update.sh: configuring git for root..."
    sudo CURL_CA_BUNDLE=/etc/ca-bundle.crt git config --global user.email "root@localhost"
    sudo CURL_CA_BUNDLE=/etc/ca-bundle.crt git config --global user.name "root at localhost"

echo "update.sh: cloning nixpkgs locally on /nixpkgs..."
    sudo CURL_CA_BUNDLE=/etc/ca-bundle.crt git clone -q https://github.com/Azulinho/mynixpkgs.git /nixpkgs

echo "update.sh: git pull on /nixpkgs..."
    cd /nixpkgs && sudo CURL_CA_BUNDLE=/etc/ca-bundle.crt git pull

echo "update.sh: checking  local_release_1703 branch..."
    cd /nixpkgs && sudo CURL_CA_BUNDLE=/etc/ca-bundle.crt git checkout local_release_1703

echo "update.sh: making sure wget is installed..."
    which wget >/dev/null 2>&1|| sudo nix-env -Q --quiet -i wget >/dev/null

echo "update.sh: making sure jdks are installed..."
    cd /tmp

    sudo wget -q --no-check-certificate -c --header='Cookie: oraclelicense=accept-securebackup-cookie' http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz || echo
    sudo nix-store -Q --quiet  --add-fixed sha256 jdk-8u131-linux-x64.tar.gz >/dev/null

set -e
echo "update.sh: running nixos-rebuild build..."
    # https://github.com/NixOS/nix/issues/443
    sudo CURL_CA_BUNDLE=/etc/ca-bundle.crt nixos-rebuild build -Q -I nixpkgs=/nixpkgs/ 2>&1 | tail 

echo "update.sh: running nixos-rebuild switch..."
    # https://github.com/NixOS/nix/issues/443
    sudo CURL_CA_BUNDLE=/etc/ca-bundle.crt nixos-rebuild switch -Q -I nixpkgs=/nixpkgs/ 2>&1 | tail

echo "update.sh: cleaning old packages..."
    sudo nix-collect-garbage -d >/dev/null 2>&1| tail

set +e
echo "finished update.sh..."
