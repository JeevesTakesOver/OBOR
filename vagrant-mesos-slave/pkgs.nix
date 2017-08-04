{ pkgs, environment, ... }:

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

    bind
    cmake
    file
    findutils
    git
    gnumake
    iptables
    iputils
    kvm
    mesos
    mosh
    netcat
    nettools
    nfs-utils
    packer
    pkgs.bundler
    python27Full
    python27Packages.ipython
    python27Packages.virtualenv
    telnet
    tig
    tmux
    vagrant
    vim
    wget
    xorg.xauth
  ];
}
