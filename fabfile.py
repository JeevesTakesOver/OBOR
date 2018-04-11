# vim: ai ts=4 sts=4 et sw=4 ft=python fdm=indent et
""" OBOR fabfile.py """

# Copyright (C) 2016 Jorge Costa

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
import sys
import json
from time import sleep
from multiprocessing import Process as mp
from profilehooks import timecall
from jinja2 import Template
from retrying import retry
import yaml
from fabric.api import task, env, local, parallel
from fabric.operations import sudo
from fabric.contrib.project import rsync_project
from fabric.context_managers import settings, prefix
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
sys.setrecursionlimit(30000)
# pylint: disable=wrong-import-position
from bookshelf.api_v2.logging_helpers import (log_green, log_red)


@timecall(immediate=True)
@retry(stop_max_attempt_number=3, wait_fixed=10000)
def install_terraform(version='0.11.2'):
    """ Installs Terraform locally """

    local('wget -q -c https://releases.hashicorp.com/terraform/{}/'
          'terraform_{}_linux_amd64.zip'.format(version, version))
    local('rm -f terraform')
    local('unzip -qq terraform_{}_linux_amd64.zip'.format(version))
    local('chmod +x terraform')


@task
@timecall(immediate=True)
@retry(stop_max_attempt_number=3, wait_fixed=10000)
def step_01_create_hosts(tf_j2_template='templates/main.tf.j2'):
    """ provisions new EC2 instances """
    cfg = Template(open(tf_j2_template).read())

    # we need to read the json to get the CFG values
    # and we also need to set them, as they won't be set on OBOR configs

    with open('config/config.json') as json_data:
        obor = json.load(json_data)

    with open('main.tf', 'w') as manifest:
        manifest.write(
            cfg.render(
                key_pair=obor['aws']['key_pair'],
                key_filename=obor['aws']['key_filename'],
                aws_dns_domain=obor['aws']['aws_dns_domain'],
                region=obor['aws']['region'],
                instance_type=obor['aws']['instance_type']
            )
        )

    install_terraform()
    local("./terraform init > "
          "log/`date '+%Y%m%d%H%M%S'`.terraform.init.log 2>&1")
    local("echo yes | ./terraform apply > "
          "log/`date '+%Y%m%d%H%M%S'`.terraform.apply.log 2>&1")


@task
@retry(stop_max_attempt_number=3, wait_fixed=10000)
def clean():
    """ destroy all VMs """
    log_green('running clean')

    jobs = []
    jobs.append(
        mp(target=destroy_railtrack)
    )
    jobs.append(
        mp(
            target=local,
            args=("echo yes| ./terraform destroy "
                  "> log/`date '+%Y%m%d%H%M%S'`.terraform.destroy.log 2>&1",)
        )
    )
    for job in jobs:
        job.start()

    exit_code = 0
    for job in jobs:
        job.join()
        exit_code = exit_code + job.exitcode

    if exit_code != 0:
        raise Exception('clean failed')
    log_green('running clean completed')


@task
def config_json(config_yaml):
    """ generates the config.json for nixos """
    with open(config_yaml, 'r') as cfg_yaml:
        with open('config/config.json', 'w') as cfg_json:
            json.dump(
                yaml.safe_load(cfg_yaml.read()),
                cfg_json,
                sort_keys=True,
                indent=4
            )


@task
@parallel
def convert_os_to_nixos():
    """
        Converts most Cloud instances to nixos automatically.
        Since hardly any cloud providers have nixos images, we use nixos-infect
        to recycle an existing OS into a nixos box.
    """
    sudo("test -e nixos-in-place || " +
         "git clone https://github.com/jeaye/nixos-in-place.git")
    with settings(warn_only=True):
        sudo("cd nixos-in-place && bash -c 'echo yy | " +
             "REPLY=y ./install -g /dev/xvda' && reboot")


@task
@retry(stop_max_attempt_number=3, wait_fixed=10000)
def update(rsync='yes', nix_gc='yes', nix_release='17.03', switch='no'):
    """ deploy or update OBOR on a host """
    log_green('running update on {}'.format(env.host_string))
    local('rm -f {}/result'.format(env.host_string))

    yes_answers = ['yes', 'y', 'YES', 'Y', 'True', 'true']

    if rsync in yes_answers:
        with settings(
            warn_only=True,
            shell='/run/current-system/sw/bin/bash -l -c'
        ):
            rsync_project(
                remote_dir='/etc/nixos/',
                local_dir=env.host_string + '/',
                delete=True,
                extra_opts='--rsync-path="sudo rsync"',
                default_opts='-chavzPq',
                ssh_opts=' -o UserKnownHostsFile=/dev/null ' +
                '-o StrictHostKeyChecking=no '
            )
            rsync_project(
                remote_dir='/etc/nixos/common',
                local_dir='common/',
                delete=True,
                extra_opts='--rsync-path="sudo rsync"',
                default_opts='-chavzPq',
                ssh_opts=' -o UserKnownHostsFile=/dev/null ' +
                '-o StrictHostKeyChecking=no '
            )
            rsync_project(
                remote_dir='/etc/nixos/config',
                local_dir='config/',
                delete=True,
                extra_opts='--rsync-path="sudo rsync"',
                default_opts='-chavzPq',
                ssh_opts=' -o UserKnownHostsFile=/dev/null ' +
                '-o StrictHostKeyChecking=no '
            )

    with settings(
        warn_only=True,
        shell='/run/current-system/sw/bin/bash -l -c'
    ):
        sudo('rm -f /etc/nixos/result')
        if nix_gc in yes_answers:
            sudo('nix-collect-garbage -d >/dev/null')
        sudo(
            'nix-channel --add '
            'https://nixos.org/channels/nixos-{} nixos'.format(nix_release)
        )
        sudo('nix-channel --update')
        sudo('which wget >/dev/null 2>&1|| '
             'nix-env -Q --quiet -i wget >/dev/null')

        sudo('wget -c -qq --no-cookies  --no-check-certificate '
             '--header "Cookie: oraclelicense=accept-securebackup-cookie"  '
             'http://download.oracle.com/otn-pub/java/jdk/'
             '8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/'
             'jdk-8u141-linux-x64.tar.gz')
        sudo('nix-store --add-fixed sha256 jdk-8u141-linux-x64.tar.gz')

        sudo('wget -c -qq --no-cookies  --no-check-certificate '
             '--header "Cookie: oraclelicense=accept-securebackup-cookie"  '
             'http://download.oracle.com/otn-pub/java/jdk/'
             '/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/'
             'jdk-8u161-linux-x64.tar.gz')
        sudo('nix-store --add-fixed sha256 jdk-8u161-linux-x64.tar.gz')

    def _nixos_rebuild():
        """ wrapper for nixos-rebuild """
        with settings(
            shell='/run/current-system/sw/bin/bash -l -c'
        ):
            sudo('nixos-rebuild build -Q')
            sudo('nixos-rebuild boot -Q')

    def _nixos_switch():
        """ wrapper for nixos-rebuild """
        with settings(
            shell='/run/current-system/sw/bin/bash -l -c'
        ):
            sudo('nixos-rebuild switch -Q')

    _nixos_rebuild()

    if switch in yes_answers:
        _nixos_switch()

    sudo('rm -rf /etc/nixos/config/*')


@task
@retry(stop_max_attempt_number=6, wait_fixed=90000)
def acceptance_tests_mesos_master():
    """ run acceptance tests on mesos master """
    local(
        "testinfra --connection=ssh --ssh-config=ssh.config "
        "-v -n 9  --hosts='{}' "
        "-m 'dnsmasq or docker or marathon_lb or marathon or mesos-dns or "
        "mesos_master or tincd or zookeeper or dns_resolution' "
        "tests".format(env.host_string)
    )


@task
@retry(stop_max_attempt_number=6, wait_fixed=90000)
def acceptance_tests_mesos_slave():
    """ run acceptance tests on mesos slave """
    local(
        "testinfra --connection=ssh --ssh-config=ssh.config "
        "-v -n 9 --hosts='{}' "
        "-m 'mesos_slave or tincd or docker or dns_resolution' "
        "tests".format(env.host_string)
    )


@task
@retry(stop_max_attempt_number=3, wait_fixed=10000)
def destroy_railtrack():
    """ destroys Railtrack VMs """

    local("cd Railtrack && "
          "pip install -r requirements.txt >"
          "../log/`date '+%Y%m%d%H%M%S'`."
          "pip.install.requirements.txt.log 2>&1")

    railtrack_env = [
        "eval `ssh-agent`",
        "ssh-add Railtrack/key-pairs/*.priv"
    ]

    # local() doesn't support most context managers
    # so let's bake a local environment file and consume as a prefix()
    with open('shell_env', 'w') as shell_env:
        for line in railtrack_env:
            shell_env.write(line + '\n')
    local('chmod +x shell_env')

    with settings(shell='/run/current-system/sw/bin/bash -l -c'):
        with prefix(". ./shell_env"):  # pylint: disable=not-context-manager
            local("cd Railtrack && "
                  "fab -f tasks/fabfile.py clean "
                  "> ../log/`date '+%Y%m%d%H%M%S'`.railtrack.clean.log 2>&1")


@task
@retry(stop_max_attempt_number=3, wait_fixed=10000)
def spin_up_railtrack():
    """ deploys Railtrack locally """

    with settings(warn_only=True):
        local('git clone https://github.com/JeevesTakesOver/Railtrack.git')

    local('cd Railtrack && git fetch --all --tags && git checkout v1.0.1')

    # make sure we are able to consume these key pairs
    local('chmod 700 Railtrack')
    local('chmod 400 Railtrack/key-pairs/*.priv')

    local("cd Railtrack && "
          "pip install -r requirements.txt >"
          "../log/`date '+%Y%m%d%H%M%S'`."
          "pip.install.requirements.txt.log 2>&1")

    railtrack_env = [
        "eval `ssh-agent`",
        "ssh-add Railtrack/key-pairs/*.priv"
    ]

    # local() doesn't support most context managers
    # so let's bake a local environment file and consume as a prefix()
    with open('shell_env', 'w') as shell_env:
        for line in railtrack_env:
            shell_env.write(line + '\n')
    local('chmod +x shell_env')

    with settings(shell='/run/current-system/sw/bin/bash -l -c'):
        with prefix(". ./shell_env"):  # pylint: disable=not-context-manager
            local("cd Railtrack && "
                  "fab -f tasks/fabfile.py step_01_create_hosts"
                  " > ../log/`date '+%Y%m%d%H%M%S'`.railtrack.step01.log 2>&1")


@task
@retry(stop_max_attempt_number=3, wait_fixed=90000)
def provision_railtrack():
    """ deploys Railtrack locally """

    local("cd Railtrack && "
          "pip install -r requirements.txt >"
          "../log/`date '+%Y%m%d%H%M%S'`."
          "pip.install.requirements.txt.log 2>&1")

    railtrack_env = [
        "eval `ssh-agent`",
        "ssh-add Railtrack/key-pairs/*.priv"
    ]

    # local() doesn't support most context managers
    # so let's bake a local environment file and consume as a prefix()
    with open('shell_env', 'w') as shell_env:
        for line in railtrack_env:
            shell_env.write(line + '\n')
    local('chmod +x shell_env')

    with settings(shell='/run/current-system/sw/bin/bash -l -c'):
        with prefix(". ./shell_env"):  # pylint: disable=not-context-manager
            local("cd Railtrack && "
                  "fab -f tasks/fabfile.py run_it"
                  "> ../log/`date '+%Y%m%d%H%M%S'`.railtrack.run_it.log 2>&1")
            local("cd Railtrack && "
                  "fab -f tasks/fabfile.py acceptance_tests"
                  "> ../log/`date '+%Y%m%d%H%M%S'`."
                  "railtrack.acceptance_tests.log 2>&1")


@task  # NOQA
def jenkins_build():
    """ runs a jenkins build """
    # clean previous build logs
    local('rm -f log/*')

    @retry(stop_max_attempt_number=3, wait_fixed=10000)
    def _provision_obor():
        log_green('running _provision_obor')

        count = 1
        while True or count > 3:
            nodes = [
                'root@mesos-zk-01-public.aws.azulinho.com',
                'root@mesos-zk-02-public.aws.azulinho.com',
                'root@mesos-zk-03-public.aws.azulinho.com',
                'root@mesos-slave-public.aws.azulinho.com'
            ]

            jobs = []
            for node in nodes:
                jobs.append(
                    mp(
                        target=local,
                        args=("fab -H %s update " % node +
                              "> log/`date '+%Y%m%d%H%M%S'`." +
                              "%s.provision.log 2>&1" % node,)
                    )
                )
            for job in jobs:
                job.start()

            exit_code = 0
            for job in jobs:
                job.join()
                exit_code = exit_code + job.exitcode

            if exit_code == 0:
                break
            count = count + 1

        log_green('_provision_obor completed')

    def _reload_obor():
        log_green('running _reload_obor')

        for target in [
                'root@mesos-zk-01-public.aws.azulinho.com',
                'root@mesos-zk-02-public.aws.azulinho.com',
                'root@mesos-zk-03-public.aws.azulinho.com',
                'root@mesos-slave-public.aws.azulinho.com'
        ]:
            with settings(
                host_string=target,
                warn_only=True,
                shell='/run/current-system/sw/bin/bash -l -c'
            ):
                local(
                    "ssh -o UserKnownHostsFile=/dev/null "
                    "-o StrictHostKeyChecking=no {} "
                    "nohup shutdown -r now &".format(target)
                )

        log_green('_reload_obor completed')

    def _test_obor():
        log_green('running _test_obor')

        for target in [
                'root@mesos-zk-01-public.aws.azulinho.com',
                'root@mesos-zk-02-public.aws.azulinho.com',
                'root@mesos-zk-03-public.aws.azulinho.com',
        ]:
            local(
                "fab -H {} acceptance_tests_mesos_master".format(target) +
                "> log/`date '+%Y%m%d%H%M%S'`."
                "{}.test_obor.log 2>&1".format(target)
            )

        target = 'root@mesos-slave-public.aws.azulinho.com'
        local("fab -H {} acceptance_tests_mesos_slave".format(target) +
              "> log/`date '+%Y%m%d%H%M%S'`."
              "{}.test_obor.log 2>&1".format(target))

        log_green('_test_obor completed')

    def _flow1():
        # spin up and provision the Cluster
        step_01_create_hosts()
        sleep(45)  # allow VMs to boot up
        _provision_obor()

    def _flow2():
        # spin up Railtrack, which is required for OBOR
        spin_up_railtrack()
        sleep(45)  # allow VMs to boot up
        provision_railtrack()

    try:
        p_flow1 = mp(target=_flow1)
        p_flow2 = mp(target=_flow2)

        p_flow1.start()
        p_flow2.start()

        p_flow1.join()
        p_flow2.join()

        # reload after initial provision
        _reload_obor()

        sleep(180)  # allow the start services

        # test all the things
        _test_obor()

        # and now destroy Railtrack and mesos VMs
        clean()
    except:  # noqa: E722 pylint: disable=bare-except
        log_red("jenkins_build() FAILED, aborting...")
        clean()
        sys.exit(1)


#
#   ___main___
#

env.connection_attempts = 10
env.timeout = 30
env.warn_only = False
env.disable_known_hosts = True
