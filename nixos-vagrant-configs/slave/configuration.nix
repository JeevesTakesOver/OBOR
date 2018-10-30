# configuration.nix
{ pkgs, boot, filesystems, networking, services, swapDevices, ... }:

{

  nixpkgs.config.allowBroken = true;

  imports = [
    ./hardware-configuration.nix
    ./vagrant.nix
    /etc/nixos/common/clusterMS.nix
  ];


  networking.extraHosts = ''
    127.0.0.1 slave slave.vagrant
  '';

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.checkJournalingFS = false;
  boot.initrd.availableKernelModules = [ "ata_piix" ];

  security.sudo.configFile =
    ''
      Defaults:root,%wheel env_keep+=LOCALE_ARCHIVE
      Defaults:root,%wheel env_keep+=NIX_PATH
      Defaults:root,%wheel env_keep+=TERMINFO_DIRS
      Defaults env_keep+=SSH_AUTH_SOCK
      Defaults lecture = never
      root   ALL=(ALL) SETENV: ALL
      %wheel ALL=(ALL) NOPASSWD: ALL, SETENV: ALL
    '';

  swapDevices = [ { device = "/swapfile"; size = 2048; } ];

  services.openssh.enable = true;
  services.dbus.enable    = true;
  services.timesyncd.enable = true;
  virtualisation.virtualbox.guest.enable = true;


  # Creates a "vagrant" users with password-less sudo access
  users = {
    extraGroups = [ { name = "vagrant"; } { name = "vboxsf"; } ];
    extraUsers  = [
      # Try to avoid ask password
      { name = "root"; password = "vagrant"; }
      {
        description     = "Vagrant User";
        name            = "vagrant";
        group           = "vagrant";
        extraGroups     = [ "users" "vboxsf" "wheel" ];
        password        = "vagrant";
        home            = "/home/vagrant";
        createHome      = true;
        useDefaultShell = true;
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
        ];
      }
    ];
  };

  # Packages for Vagrant
  environment.systemPackages = with pkgs; [
    findutils
    gnumake
    iputils
    jq
    nettools
    netcat
    nfs-utils
    rsync
  ];


   # this will configure this host as a zookeeper node and mesos-master,
   # deploying all the required services.
  services.clusterMS = {
    enable = true;

    zk_string = "zk://10.254.0.11:2181,10.254.0.12:2181,10.254.0.13:2181/mesos";
    zk_node01 = "10.254.0.11";
    zk_node02 = "10.254.0.12";
    zk_node03 = "10.254.0.13";

    # our slaves DNS query our mesos-masters
    dns_resolver1 = "10.254.0.11";
    dns_resolver2 = "10.254.0.12";

    # TODO: rename this
    consul_other_node = "10.254.0.11";

    # local node TINC settings
    tinc_ip_address = "10.254.0.14";
    tinc_domain = "tinc-core-vpn";
    tinc_interface = "tinc.core-vpn";
    tinc_compression = "6";
    tinc_hostname = "slave"; # we're just called slave (bit lazy I know)
    tinc_network = "core-vpn";
    tinc_network_netmask = "24";
    tinc_public_key = ''
      -----BEGIN RSA PUBLIC KEY-----
      MIIBCgKCAQEA4p8OuuUaiw4TorLyZLxn3Xx1NVxcyqD5EwrslGJnKIkQrPuFb8Y8
      hJN7tiJRKh/DFhh4PT8+e7IR+JtSvq4z879PWAe2suwAFnC2lyEDKn0TvuOachON
      ZiTwPrXOr5CxoBxNunS+9Mipzu6Go+PrRPejza1hBAIZY1q8voPwaiGmbKTOg1xp
      5UB5+RsOKgMoPsV0+ZakCuMY1ccgLSvAgwhImI01tv8OKYNgr4ipBM9hVV3oTj3e
      c27sY8Sv7YaOnqlZpcphiHEkpZSgC5EngHq+80uNtf/CjfpihZbWN2Wn3l/3MA8f
      bhxEqnOfvT7OMhZUDNo5ny8A8C+dZBh81QIDAQAB
      -----END RSA PUBLIC KEY-----
      '';
    tinc_private_key = ''
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpAIBAAKCAQEA4p8OuuUaiw4TorLyZLxn3Xx1NVxcyqD5EwrslGJnKIkQrPuF
      b8Y8hJN7tiJRKh/DFhh4PT8+e7IR+JtSvq4z879PWAe2suwAFnC2lyEDKn0TvuOa
      chONZiTwPrXOr5CxoBxNunS+9Mipzu6Go+PrRPejza1hBAIZY1q8voPwaiGmbKTO
      g1xp5UB5+RsOKgMoPsV0+ZakCuMY1ccgLSvAgwhImI01tv8OKYNgr4ipBM9hVV3o
      Tj3ec27sY8Sv7YaOnqlZpcphiHEkpZSgC5EngHq+80uNtf/CjfpihZbWN2Wn3l/3
      MA8fbhxEqnOfvT7OMhZUDNo5ny8A8C+dZBh81QIDAQABAoIBAQC9FQs8QxW/ehJG
      CNqX1F8w/LvqttKxOlg3XEECmYwK1Tn1qrKuDQ/HaiqpT766z999GxOPvqoKmQvH
      iwkiEcVFFZVFFMKKTMDR+F9Qf3ndxJhqCAuALPIojJ9rI1R9RdP+jD8KWIhPQvHz
      ty7dpbhSRfEFFilBJ+M486dRqlI4qaKUNWhNgguDBHPUR3Kcpr5zA/nkQIiUPV/L
      xJsu7xpc1jJO7OuoANBiyCJ3IOqdRmY/K7JW2eUgzDeGfLvu4aHMbEXHk1d8gQlJ
      hlDcBf+Jh7dHK0mvSR1osmofWkL9IwtdYdLsK6um+i4c9VJW4is2PJzjePywHpas
      YOpu4GJhAoGBAPvoCD0wWNbBZfHKv6n+pnvYP1gADuFdJ1R90e0ySC8aNVmNWP44
      LVoW8OC0T54Jw/3UYAeRGNJLnDdvARAVKpnIMx1Nv2ArCrozFVQSSs/E8M/HBVbP
      mXoXJCWlGr2dVqszhpz2hX7j0msTU155j22LG15EudBDU77szgEdZ4GJAoGBAOZN
      1fVOmignUEcEjFH7Ay6qS06J73Jkq8wqgYiGtOBDfBs12TdC/B4nApe6+V0WXxq5
      ZHTKU8j0tOgFUnYI4eMkAlp1EtoAeHb5DRgi6OhL2dtAuwwEg180P/hbTEfCOQHv
      3aKAOBidBoIKuqpUg24T1dfN7rggvnnKh1YiycntAoGBAO60Awqog6aNASNMMq7N
      pcj5M50aAP/BHAHOcFzKJuirdx5y+H99kEwsLPlhI4joTBZ9ZroE3nZ4O4Gz6Ffr
      FsE+mmEMSWrBnpquyWkvJEEZp+/b8c0/T3oH77LUbzB6paP5YXffisSg8cWRPJDr
      s+Pjy31atpEJG5RyJQudZ3WxAoGAFvxbx3EB59IMrBnjG2ePKMAsZflUYbl0gBsZ
      9JNlSCDUKS8Vr/NKkIPaOWSa8NSDx3oLcbCj7iGmUKX/VfKLAQ2eAoM+z21OmKlA
      ylDpqA2x/7UVNhzZM85WOCZ8lYjoAa58E3TypFo/xQjnGor21yy5oiFWmyABgsxY
      95rfQv0CgYBFmVC/4mAjt63lQQjubyu8W+1E33nkXjeydtVFtOUbFWMqWtXwMyJE
      yf4otjsK6OKmG1fnWbpxOBAg7TplYW6Zib9pguTaxD82Edb6JEhOc5+K0wZYXVQt
      X55umOXkMU41bBCN5fN1eS0bkZxo3O+pXex41HE6g05xBp4DCsXrMQ==
      -----END RSA PRIVATE KEY-----
        '';

    # core nodes (Railtrack) settings
    tinc_core_node01_fqdn = "core01-public.aws.azulinho.com";
    tinc_core_node01_ip_address = "10.254.0.1";
    tinc_core_node01_public_key = ''
      -----BEGIN RSA PUBLIC KEY-----
      MIICCgKCAgEAozzeSS7NSQsb3s9vJS1rJAV3Z4c9ib422bAEOeK8oGcKjTKxFtaE
      9FNGT+wmvwqYz/I81YlB4MIcHojLx94PGXq8lef1awtiekpS23yeanwLFN0esPET
      Dsj51nWQ65QVcxN8cp6UODGlq8SYF8ikkkNiLyeDJabDKf8RQk5B1HhUHLbhyxJc
      FyqRiEXsBELCKVqBZEGTYeKqx8IatIfpIY0v9ddapsUQsELwSY3dLxI55sHDV5zk
      0wU3gpq1Ht6I030nxCPJ9gXXOTF6pwWUdYZyGXGnVbVRMPcxu4jfukuxf8jIWDwe
      2Iw+PRUPOl11/4sjULtqd71l8eh90I4FTAG20sHixatb4APYm7v4UXDrs57IU3PF
      NGOSYSQFDLPxRWpmtn/tY3IC5ILNXjvjWRdWIqrzz1ozzthvsqYMyqBZf8RQFN9j
      PKfK/oakrAhbBBZ4unKQD7Li3gfzUmDANy1mQXEkIjpfCLiq1C3lKkf1VnTPr9DJ
      315Acc8p6TIr+olFZVM7Fg6wCflrswJVYXy3wd9U+pfDK4d6/1va8K+2zQH9c2gE
      jy+PxPRYL0yn8EhPGc6z9Q7jFVuKOkgRDLDMmheLUAAYvhJj6d6MSDbWR5zShIds
      84wj88+90J2P+CrPbnhn7N78dfxTshR0wTAZQgUvJsqgDkRLovOTxmECAwEAAQ==
      -----END RSA PUBLIC KEY-----
    '';

    tinc_core_node02_fqdn = "core02-public.aws.azulinho.com";
    tinc_core_node02_ip_address = "10.254.0.2";
    tinc_core_node02_public_key = ''
      -----BEGIN RSA PUBLIC KEY-----
      MIICCgKCAgEA1pZWhTHR20c98RkwbHjvrVlDziK49c4nlaz1IxG3byLCKCVxNWt5
      YQFC+cPI+paMO3zWTWAF05b7yKfDLYfWXJU79EBL4kkYldAzTrUawMRYSJtItbrS
      LtEvfPBP0L82FgB/Jz7MyGU6tgnPOtMoDkO6fSLCbVKBraIAfs+uxYFjjjp7nRFA
      Atj/8iKDYOoF5Rpkd3jDpRnBUMU5jfJJiMnKK6v0cWWPmRCySdP4nkBseeibi3r3
      apuZMS59eGsBQRkJCpmGU3aQKPVYO79l+W+cWJyNspoEe7/i8uQT0fhQDInnycZu
      lrDlfY3/CkSyH0qkg9RDfE5DFfrLS4cuLdmu1ishWRLR3ANwxAExc5j7sgmveBnD
      Bj6aGG+xRirdrbyODMUxRewjkbSCZDjjIsWHPaGcK0WK+8Ri/o+xucsFnrCclEfd
      Xj7+uxdvq/8IMNGsUADhy4rjwdizNnsqPdfeJGIAgBi1of1tqpttEyLyzq0OQ27+
      jVkO7IXfq/EQR0c8hdU/D9DTD6mkVy71ScExKwcY9nUn40ssvu2cmkktuM0lq/JV
      WAxzMgL9PVcuHgd5IeusgW9qZk2wkqlKdYQIRhVgy1JFlqvMNYSqN28iIPuWWUuq
      oTzQuL7LdRO9TC6gS+JCrP03GAqpNS+q84BIXT/DJpi2+nJGkREbHd8CAwEAAQ==
      -----END RSA PUBLIC KEY-----
    '';
    tinc_core_node03_fqdn = "core03-public.aws.azulinho.com";
    tinc_core_node03_ip_address = "10.254.0.3";
    tinc_core_node03_public_key = ''
      -----BEGIN RSA PUBLIC KEY-----
      MIICCgKCAgEAlimDWppur7zym2LHca10GRipVSVTz4XSPE4bEEsjI3pGkUAt1s/9
      FlGJ3IiMtCOkbOsG3eaNK6zbYisl/n+j29EAe47U3ESzz2Mq2R4loJEJHLbuCknu
      edmUMtTT4dUIM4iJSAIQwqr7bTMID470xITkkK9yxG0LUtE0Wo73PW9Y6lm4nwKU
      9fQwCbkUAtXRR8k5z95v+l4P5G395qeG0MdZ4TlVWu+PzdMeV/uAl/tiWyGDWfkD
      6bZBsrb+89skR302ibEIf/WCWa0Gnrd5bC8SwAWI47VocF0pybWD9ImvhB4TkYHf
      mRp2k+cWxqi9IU/lCz1PTME9CaFteadYkE6mijcGPEC62QnF+jLE85vulwr9g0Lf
      yOKGgC0gqw0PgjShoQalcvD+9c+I76mEiX6NnNxIIJ5m/+Jgdn4dwh3rNc9R/R+k
      4Gs5dgf8u/1VAmXdkXpTjN/aJtwt7FOo1lkY5cYL8lIxV3xwOnYd6m3cL9dwCK97
      4mLTcJFjsRZSmTUXm9xCqZ/EYmSXviEodulvsnl8fO/1JjVxxNaV25LE71nSvF9F
      k3ud6ALnTFlKl+UrtWY199ODqK1S8lbTkso/ebLAN0zDdXXbD9KVpsSAUuNQRwop
      gpyzPAVIL9gQX373tY8y7al4cVg6hq2FHxJlAWtikFQA3dXRVH4Ix0sCAwEAAQ==
      -----END RSA PUBLIC KEY-----
    '';


  };
}
