#!/run/current-system/sw/bin/bash

function retry {
  local retry_max=$1
  shift

  local count=$retry_max
  while [ $count -gt 0 ]; do
    "$@" && break
    let count=count-1
    sleep 1
  done

  [ $count -eq 0 ] && {
    echo "Retry failed [$retry_max]: $@" >&2
    return 1
  }
  return 0
}


echo "running update.sh..."

echo "update.sh: cleaning old files..."

    sudo rm -rf /old-root
    sudo rm -rf /tmp-nixos
    sudo rm -f /etc/nixos/result

echo "update.sh: cleaning old packages..."
    sudo nix-collect-garbage -d >/dev/null 

echo "nix-channel update.... on 17.09"
    nix-channel --add https://nixos.org/channels/nixos-17.09
    nix-channel --update

echo "update.sh: making sure wget is installed..."
    which wget >/dev/null 2>&1|| sudo nix-env -Q --quiet -i wget >/dev/null

echo "update.sh: making sure jdks are installed..."
    cd /tmp

    sudo wget  --no-cookies  --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie"  http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141-linux-x64.tar.gz  || echo
    sudo nix-store -Q --quiet  --add-fixed sha256 jdk-8u141-linux-x64.tar.gz >/dev/null

set -e
echo "update.sh: running nixos-rebuild build..."
    # https://github.com/NixOS/nix/issues/443
    retry 3 sudo  nixos-rebuild build -Q

echo "update.sh: running nixos-rebuild boot..."
    # https://github.com/NixOS/nix/issues/443
    retry 3 sudo nixos-rebuild boot -Q

set +e
echo "finished update.sh..."
