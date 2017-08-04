#!/usr/bin/env bash
mkdir -p /tmp-nixos
chmod 777 /tmp-nixos
export TMPDIR=/tmp-nixos
for ta in 1 2 3 4 5 6 7 8 9 10
do
	userdel nixbld$ta || true
done
groupdel nixbld  || true
curl -L https://raw.githubusercontent.com/elitak/nixos-infect/c6e0edb73b97602550e43547bfa64f3bc9e6fe91/nixos-infect > nixos-infect
chmod 755 nixos-infect 
NIX_CHANNEL=nixos-16.09 ./nixos-infect
