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
    127.0.0.1 mesos-zk-02 mesos-zk-02.vagrant
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
    zookeeper_id = 1;

    dns_resolver1 = "10.254.0.1";
    dns_resolver2 = "10.254.0.2";

    # local node TINC settings
    tinc_ip_address = "10.254.0.12";
    tinc_domain = "tinc-core-vpn";
    tinc_interface = "tinc.core-vpn";
    tinc_compression = "6";
    tinc_hostname = "mesos_zk_02";
    tinc_network = "core-vpn";
    tinc_network_netmask = "24";
    tinc_public_key = ''
      -----BEGIN RSA PUBLIC KEY-----
      MIIBCgKCAQEAyuEFW+DPPsKMGFQkjUIiZvzRmkDibb/pdYaZR+LTEGjRh8pjK9nO
      308vn7e9ShGIaz5dWuIa2F5NAvNhCBQKmC69ygKuFOTXeZhozwr6SpIviULqWNIq
      HkZeh4J2mWqsg5Rl1yVlJSFHzmciC0PMKH/PcQ7H6TBTGqpIDKSV+dsTVCGyUEL0
      THLMffxHd+rCv1zoTVJsTKW/1mnTZuhTcCY/UUKsSAeO8d6BZwj2Wb/algCVZj+N
      5Q+0lF312irXtTyYGu3i9Ga3aFOyaO6XBFZXrJFIAVN0VmavhD7L5/4L8MO+J6a8
      ZKOu4uvHRDyepYIxhAXFqC2ZqYfhIJa9/QIDAQAB
      -----END RSA PUBLIC KEY-----
      '';
    tinc_private_key = ''
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpQIBAAKCAQEAyuEFW+DPPsKMGFQkjUIiZvzRmkDibb/pdYaZR+LTEGjRh8pj
      K9nO308vn7e9ShGIaz5dWuIa2F5NAvNhCBQKmC69ygKuFOTXeZhozwr6SpIviULq
      WNIqHkZeh4J2mWqsg5Rl1yVlJSFHzmciC0PMKH/PcQ7H6TBTGqpIDKSV+dsTVCGy
      UEL0THLMffxHd+rCv1zoTVJsTKW/1mnTZuhTcCY/UUKsSAeO8d6BZwj2Wb/algCV
      Zj+N5Q+0lF312irXtTyYGu3i9Ga3aFOyaO6XBFZXrJFIAVN0VmavhD7L5/4L8MO+
      J6a8ZKOu4uvHRDyepYIxhAXFqC2ZqYfhIJa9/QIDAQABAoIBAQCVmMl/z0xiRchR
      5DGzq5F8iW3xJWkRblKyo5aBKGNkFTZzv6vS2N+vUE+YoT7F0BnconbqHhGXfCmj
      RF1HPKf3QXgW7lT4+Sld8yFNkhWvSQ4eU6ZD6my+ODtaBrx3Me6Vc6aIt31WnKy7
      KNc0oUB4mI4ZGsIUU9rjra5FDFO+kRdxXXhrhaw/RpSEQyF4Ajbszb4N7B/a07uZ
      viCLiB0woo/tZspzynQWT/gQ1WZ35PVrlsv2rkT9ueJL0MaAEOaPFr+d+AoYcm+m
      LSXfWM47olVtEDCV6tcIJufM4LY4O5AH+J2XGAUAvVavETBHkxSDocHg6C/opTVw
      bz55AfnhAoGBAPvTSZp5TMzbxjvB+Hxk/S4H+9nPuYhOS0iT0RAavYZ7bR0D9JGZ
      GROBq5ur5RcdIwJjUE62l8qhEfIfbdLUJ8tgTH/s7nQQE3UpuuoQY07c27vUx5nr
      CRylZ4GnIJx19KIIOob/ROS3vV2lp/9VybDfsZycRlj+OblqKeSqcxEZAoGBAM4+
      AwJPkuAgPQB5hd0EBc0hAc27GusGCBaH/VrcHJl+DlSET2cjeJO/5MH9dOUoY9Y6
      0FFLYNz8HFC0tr4N/N42TQ5ROk22F2hRx65I90c4MzWOr1D/29Jhd15Ioe7KSdRY
      9JOCjsZq4tsZMJCzigqKGwjqjhhvYMEbCe6J1TyFAoGBALlF/TwKjIeYFmO21TPo
      NSGdvBzHKLBxMhBGuKTJl7EOs/uKAnDwm7NvTqusr1LvG+fQ26/dxRXOpV5m4y0e
      69xEkGP6FIINpdMojZ1Ry06lTYEHDodelgieZOXN6T9TxVVFCpJx0uUXjdoNW+mO
      22InYgxgKZ2mBSA2THYxNZFZAoGBALudids2TCR670NZST8vg5+BYUSn6urWB9GH
      UCCxj4rKM3sLCbiHeg7eR9l5GjfEsF2YDx2E9s7QwWlhm8P0sY3r09ksZ19+QHjz
      vDR9yAUPyPX1oOKMfoo5g/9PD5BMkTEM4yC1afByF4C8v4NC8FZ6H/HSfgUYfOnu
      EPDgjgyJAoGAMvbp2Yy8RVT05x/WmDTqzAleeH8n0OzZXh/KgK2qvYn7BQiKWaBJ
      lm9qfECT5zIa4EfCKoxvDOfjq4GyAtIGVZtvATsfyYnaPCoB2FsBPFUymUZ0S3Ul
      3vyMz667NxXPvFG1jvG7cBXlouqCKObrrhI4XBPFJvAOZ7sLc/egcug=
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
