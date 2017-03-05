{ networking, services, ... }: {

  # ideally we want this commented out, so that we can delegate our DNS
  # tou DNSmasq running on our mesos-ZK instances.
  # however we may need to explicitly set this on our different nodes
  # as we may need them to bootstrap the server the first time when DNSmasq
  # and the VPN hasn't been set it yet.
  #networking.nameservers = [
  #    "8.8.8.8"
  #  "8.8.4.4"
  #];

  networking.enableIPv6 = false;
  networking.wireless.enable = false; #disable when using networkmanager

  networking.firewall.enable = true;
  networking.firewall.allowPing = true;

  # traffic on the tin.core-vpn interface is not restricted by iptables
  networking.firewall.trustedInterfaces = [ "tinc.core-vpn" ];

  # allow internet/external access to ssh and tincd port.
  # ssh is required for provisioning, however it could be locked down to a 
  # allow access only to a particular group of of addresses in the sshd_config 
  # file
  networking.firewall.allowedTCPPorts = [ 22 655 ];
  networking.firewall.allowedUDPPorts = [ 655 ];

  # specify the list of primary network cards across the different boxes.
  # we need dhcpcd allocation locked down to the primary interfaces
  # as we don't want dhcpcpd to attempt to allocate ip addresses for the
  # tinc vpn interfaces.
  # locking them them ensures this won't happen
  networking.dhcpcd.allowInterfaces = [ "enp0s3" "enp5s0" "enp0s8"];

  # not entirelly sure we care about this block.
  services.udev.extraRules = ''
    KERNEL=="eth*", ATTR{address}=="", NAME="eth0"
    KERNEL=="eth*", ATTR{address}=="", NAME="eth1"
  '';

  #networking.bridges.cbr0.interfaces = [];
  #networking.interfaces.cbr0 = {};
  #virtualisation.docker.extraOptions = "--iptables=false --ip-masq=false -b cbr0";

  # consume a local proxy
  # networking.proxy.default = "http://192.168.1.253:3128";

}
