#!/usr/bin/env bash
curl -L https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect > nixos-infect
chmod 755 nixos-infect
mkdir tmp
export TMPDIR=/root/tmp
./nixos-infect
