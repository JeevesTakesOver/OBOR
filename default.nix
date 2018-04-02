with import <nixpkgs> {};
with pkgs.python27Packages;

stdenv.mkDerivation {
  name = "impurePythonEnv";
  buildInputs = [
    # these packages are required for virtualenv and pip to work:
    #
    python27Full
    python27Packages.virtualenv
    python27Packages.pip
    # the following packages are related to the dependencies of your python
    # project.
    # In this particular example the python modules listed in the
    # requirements.tx require the following packages to be installed locally
    # in order to compile any binary extensions they may require.
    #
    stdenv
    openssl
    libxml2
    libxslt
    libzip
    zlib
    unzip
  ];
  src = null;
  shellHook = ''
  # set SOURCE_DATE_EPOCH so that we can use python wheels
  SOURCE_DATE_EPOCH=$(date +%s)
  # create a virtualenv outside the mesos workspace
  # due to long paths that break shebangs
  export VENV=/tmp/$$
  rm -rf venv
  virtualenv  --no-setuptools --no-pip --clear $VENV > log/`date '+%Y%m%d%H%M%S'`.venv.log 2>&1
  ln -s $VENV venv
    . venv/bin/activate
    export PATH=$VENV/bin:$PATH
  wget -c https://bootstrap.pypa.io/get-pip.py
  python get-pip.py
  pip install --quiet --upgrade -r requirements.txt > log/`date '+%Y%m%d%H%M%S'`.pip.install.log 2>&1
  pip install --quiet --upgrade -r dev-requirements.txt > log/`date '+%Y%m%d%H%M%S'`.pip.install.dev.log 2>&1
  export PS1="$PS1::nix-shell()"
  '';
}
