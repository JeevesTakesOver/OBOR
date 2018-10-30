# configuration.nix
{ pkgs, boot, filesystems, networking, services, swapDevices, ... }:

{

  nixpkgs.config.allowBroken = true;

  imports = [
    ./hardware-configuration.nix
    ./vagrant.nix
    /etc/nixos/common/clusterMM.nix
  ];


  networking.extraHosts = ''
    127.0.0.1 mesos-zk-03 mesos-zk-03.vagrant
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
  services.clusterMM = {
    enable = true;

    zk_string = "zk://10.254.0.11:2181,10.254.0.12:2181,10.254.0.13:2181/mesos";
    zk_node01 = "10.254.0.11";
    zk_node02 = "10.254.0.12";
    zk_node03 = "10.254.0.13";
    zookeeper_id = 2;

    dns_resolver1 = "10.254.0.1";
    dns_resolver2 = "10.254.0.2";
    consul_other_node = "10.254.0.11";

    # local node TINC settings
    tinc_ip_address = "10.254.0.13";
    tinc_domain = "tinc-core-vpn";
    tinc_interface = "tinc.core-vpn";
    tinc_compression = "6";
    tinc_hostname = "mesos_zk_03";
    tinc_network = "core-vpn";
    tinc_network_netmask = "24";
    tinc_public_key = ''
      -----BEGIN RSA PUBLIC KEY-----
      MIIBCgKCAQEAthCd7Omce/nHG7MyPDqYt9E5SzyC8gh3YHMPLdedsf7vgIQwPVs4
      qU0JlvADuM+Z99j4eAHKDEeCzagx4XV2GNVkhQcBiis31i/qoVwZHuAuAWCgzaFD
      X4QOMgC9mU7G2oOiOaAhbs/NynWq5lTtj+s60sIclYxv5wsy5FJ1S3I9UgvG+cRH
      bJKX4giWVPAWsYo4RYOnQiSKt1+3JyXJcUbHuLjRAMuX4ORWFTayFaRMXpfiPmbu
      rUIJVzpPrR2VWdI5WfnjmUu+4+Oi3fLdIOyRJlZtXnbbwKUjueaUH4oBnNIluzRK
      U+NdiEinxpvMuSOmQvy5EPL6WmJQ981ZYwIDAQAB
      -----END RSA PUBLIC KEY-----
      '';
    tinc_private_key = ''
      -----BEGIN RSA PRIVATE KEY-----
      MIIEowIBAAKCAQEAthCd7Omce/nHG7MyPDqYt9E5SzyC8gh3YHMPLdedsf7vgIQw
      PVs4qU0JlvADuM+Z99j4eAHKDEeCzagx4XV2GNVkhQcBiis31i/qoVwZHuAuAWCg
      zaFDX4QOMgC9mU7G2oOiOaAhbs/NynWq5lTtj+s60sIclYxv5wsy5FJ1S3I9UgvG
      +cRHbJKX4giWVPAWsYo4RYOnQiSKt1+3JyXJcUbHuLjRAMuX4ORWFTayFaRMXpfi
      PmburUIJVzpPrR2VWdI5WfnjmUu+4+Oi3fLdIOyRJlZtXnbbwKUjueaUH4oBnNIl
      uzRKU+NdiEinxpvMuSOmQvy5EPL6WmJQ981ZYwIDAQABAoIBAATsNhjtyBliC4wo
      MDeIrhBqS85I+JFqwS+ObN6kcdMaPYeQC23dRY7uUlAOdUtN8a/N4gn8omXqmRLO
      dWrPLj5Fps4h/lyqBnx4FzP9tYAsN5I59p8YuSWgAHJBqt62TpIh9QTx23WPkNTk
      kZZgvXuitJh2PyecAHqSxvF9eUZs6JaYBxZNdiYFFxK4ALuvIZ3c8/3Zhcsu6Fem
      z9eYEfp+ay7BA+yOM+pplR8NwmmtI1JENNh9yjXzy/jTumLQ0NMHM2jzWdGzFp1p
      UoDX6sQAvqYvxtjhIEBsCQHKITIJLMLGg1AFUThhYJa8i9DPGh0FSmmeYq6UPYmR
      JVS6pcECgYEA75V7VU+rdLXo8AVJWsQIjohh5mOsS+3yM0pJ6ejs7uBNyH4RkLY1
      ocKviED5EHWNvskuPUj+QjPDHxzGAN8CxUS3R2a/YsYg+h0V3ohf/hYSczFQkSHM
      AZtTklKphS47wkPBi5o2xFM+qmEUwyN/aM2ij69/eUSlFABk2HOMRokCgYEAwooz
      KavAV7NOMWzFqyRIbW9JkZ8qn2qh8MWfaOwtEawTVlG9ZshBheu25NouZQeX2ocI
      sGpWXn+P+Sm9O/IMavnw/FR9tv5gd0TKT94uYH+ndV8AgpIyfXYuHGiE3KSu7Uvg
      6hZ/XeI36zDc17ph5DDvi3cO1MBTFXn2sgiXZYsCgYEAlnJl6mKHJlj9F4waTjb/
      sJGP+J7qmRuolfC2jX5JGpAcCCSyXw8sipG4rHUwcdd/1Sh8MtvdXjEm/CiTZgSk
      tr+538pzsFD+cFFHZGB69xFhMJjtINX6R6AEUMQ703f+6rSlm0aR0aL8nP0tjoSC
      A4vt4xCvmbUzfGXq7clRcxECgYBs3/d+TNcavgj29E80VtwKEwxzaUbrbTwwigmL
      KRKYH1u7JYgAq/avwpnbPphUholgDc65HOo1fOLQqaF0mSSGAlfygD7TWU4XsfIf
      /NKrwwWvVHnumW+Uc72evIgPDEOyHpNDr0+c9WwiPnh6a585nIGT5g/w1aoqDNYa
      EWDZvQKBgExWeV8rN8Skkc81NdXwIJTYTaiswbLc0fycZdbdget7vm7OwCw/PSQR
      Rz+W6+qlKxEiVh2ghegElsE1fy3M7uShdAc4Peei2bZeMR4Emkj0y2gqgDLkf48v
      QE7NgfYEZ9dZsbdfEzd9xB+RKaFrs3VeIfSWiObxiH5ou8XysEGw
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
