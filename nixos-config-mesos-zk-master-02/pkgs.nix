{ pkgs, nixpkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    # vim setup
    (
    with import <nixpkgs> {};

      vim_configurable.customize {
        # Specifies the vim binary name.
        # E.g. set this to "my-vim" and you need to type "my-vim" to open this vim
        # This allows to have multiple vim packages installed (e.g. with a different set of plugins)
        name = "vim";

        vimrcConfig.customRC = ''
          if filereadable("/etc/nixos/common/vim/vimrc")
            source /etc/nixos/common/vim/vimrc
          endif
        '';
      }
    )

    (
      let
        vim = lib.overrideDerivation pkgs.vim_configurable (o: {
            aclSupport              = false;
            cscopeSupport           = true;
            darwinSupport           = false;
            fontsetSupport          = true;
            ftNixSupport            = true;
            gpmSupport              = true;
            hangulinputSupport      = false;
            luaSupport              = true;
            multibyteSupport        = true;
            mzschemeSupport         = true;
            netbeansSupport         = false;
            nlsSupport              = false;
            perlSupport             = false;
            pythonSupport           = true;
            rubySupport             = true;
            sniffSupport            = false;
            tclSupport              = false;
            ximSupport              = false;
            xsmpSupport             = false;
            xsmp_interactSupport    = false;
        });
      in vim
    )

    acl
    acpi
    ag
    aspell
    at
    atop
    attr
    autoconf
    avahi
    banner
    bash
    bashCompletion
    bc
    bind
    bindfs
    binutils
    bsdiff
    btar
    bzip2
    psmisc
    ctags
    direnv
    file
    findutils
    firmwareLinuxNonfree
    gnugrep
    gnupg20
    iotop
    iputils
    libffi
    libmtp
    logstash-forwarder
    logstash-contrib
    netcat
    nettools
    networkmanager
    nmap
    ngrep
    openssh
    openssl_1_1_0
    oraclejdk8
    powerline-fonts
    python27Full
    python27Packages.ipython
    python27Packages.virtualenv
    python35Packages.ipython
    nssmdns
    rsync
    lsof
    mesos-dns
    tcpdump
    telnet
    tmux
    vim
    wget
    ycmd
  ];
}
