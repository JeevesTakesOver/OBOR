# vim: ai ts=4 sts=4 et sw=4 ft=python fdm=indent et

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
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
sys.setrecursionlimit(30000)

from time import sleep

from fabric.api import task, env, execute, local, parallel
from fabric.operations import put, run
from fabric.contrib.project import rsync_project
from fabric.context_managers import settings, prefix

from bookshelf.api_v2.logging_helpers import (log_green, log_red)
from retrying import retry
import yaml
import json
from pathos.multiprocessing import ProcessingPool as Pool
import re


@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_package(vm, _):
    local('VAGRANT_VAGRANTFILE=Vagrantfile.%s vagrant up' % vm)


@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_up_vm_with_retry(vm):
    local('VAGRANT_VAGRANTFILE=Vagrantfile.%s vagrant up --no-provision' % vm)


@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_provision_vm_with_retry(vm):
    local('VAGRANT_VAGRANTFILE=Vagrantfile.%s vagrant provision' % vm)


@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_halt_vm_with_retry(vm):
    local('VAGRANT_VAGRANTFILE=Vagrantfile.%s vagrant halt' % vm)


@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_rsync_vm_with_retry(vm):
    local('VAGRANT_VAGRANTFILE=Vagrantfile.%s vagrant rsync' % vm)


@task
def bake_obor_box():
    """ bakes a vagrant box for OBOR """
    log_green('running bake_obor_box')

    local(
        'VAGRANT_VAGRANTFILE=Vagrantfile.vagrant-obor-box '
        'vagrant up --no-provision'
    )

    result = local('VAGRANT_VAGRANTFILE=Vagrantfile.vagrant-obor-box '
                   'vagrant ssh-config', capture=True)

    pattern = r'.*HostName\s(.*).*\n.*User\s(.*).*\n' \
              '.*Port\s(.*).*\n.*\n.*\n.*\n.*IdentityFile\s(.*)'

    regex = re.compile(pattern)
    m = regex.search(result)

    host, user, port, ssh_file = m.groups()

    local(
        'rsync --delete -chavzPq --rsync-path="sudo rsync" '
        '--rsh="ssh -F ssh.config -i {} -p {} " '
        'vagrant-mesos-zk-01 {}@{}:/etc/nixos/'.format(ssh_file,
                                                       port,
                                                       user,
                                                       host)
    )

    local(
        'rsync --delete -chavzPq --rsync-path="sudo rsync" '
        '--rsh="ssh -F ssh.config -i {} -p {} " '
        'common {}@{}:/etc/nixos/common'.format(ssh_file,
                                                port,
                                                user,
                                                host)
    )
    local(
        'rsync --delete -chavzPq --rsync-path="sudo rsync" '
        '--rsh="ssh -F ssh.config -i {} -p {} " '
        'config {}@{}:/etc/nixos/config'.format(ssh_file,
                                                port,
                                                user,
                                                host)
    )

    local(
        'VAGRANT_VAGRANTFILE=Vagrantfile.vagrant-obor-box vagrant  provision'
    )

    local(
        'rsync --delete -chavzPq --rsync-path="sudo rsync" '
        '--rsh="ssh -F ssh.config -i {} -p {} " '
        'vagrant-mesos-slave {}@{}:/etc/nixos/'.format(ssh_file,
                                                       port,
                                                       user,
                                                       host)
    )

    local(
        'rsync --delete -chavzPq --rsync-path="sudo rsync" '
        '--rsh="ssh -F ssh.config  -i {} -p {} " '
        'common {}@{}:/etc/nixos/common'.format(ssh_file,
                                                port,
                                                user,
                                                host)
    )

    local(
        'rsync --delete -chavzPq --rsync-path="sudo rsync" '
        '--rsh="ssh -F ssh.config -i {} -p {} " '
        'config {}@{}:/etc/nixos/config'.format(ssh_file,
                                                port,
                                                user,
                                                host)
    )

    local(
        'VAGRANT_VAGRANTFILE=Vagrantfile.vagrant-obor-box vagrant  provision'
    )

    local('rm -f package.box')

    local('VAGRANT_VAGRANTFILE=Vagrantfile.vagrant-obor-box vagrant package')

    # https://github.com/minio/mc
    local('wget -c https://dl.minio.io/client/mc/release/linux-amd64/mc')
    local('chmod +x mc')

    # SET MC_CONFIG_STRING to your S3 compatible endpoint

    # minio http://192.168.1.51 \
    #    BKIKJAA5BMMU2RHO6IBB V7f1CwQqAcwo80UEIJEjc5gVQUSSx5ohQ9GSrr12 S3v4

    #    s3 https://s3.amazonaws.com BKIKJAA5BMMU2RHO6IBB \
    #    V7f1CwQqAcwo80UEIJEjc5gVQUSSx5ohQ9GSrr12 S3v4

    #    gcs  https://storage.googleapis.com BKIKJAA5BMMU2RHO6IBB \
    #    V8f1CwQqAcwo80UEIJEjc5gVQUSSx5ohQ9GSrr12 S3v2
    #
    # SET MC_SERVICE to the name of the S3 endpoint
    # (minio/s3/gcs) as the example above
    #
    # SET MC_PATH to the S3 bucket folder path

    local('./mc config host add %s' % os.getenv('MC_CONFIG_STRING'))
    local('./mc cp package.box %s/%s/vagrant-obor.box' % (
        os.getenv('MC_SERVICE'),
        os.getenv('MC_PATH'))
    )

    local('vagrant box add vagrant-obor-box package.box --force')
    local('rm -f package.box')

    log_green('bake_obor completed')


@task
def spin_up_obor():
    log_green('running spin_up_obor')

    for vm in [
        'vagrant-mesos-zk-01',
        'vagrant-mesos-zk-02',
        'vagrant-mesos-zk-03',
        'vagrant-mesos-slave'
    ]:
        vagrant_up_vm_with_retry(vm)
        sleep(5)
        vagrant_rsync_vm_with_retry(vm)

    log_green('spin_up_obor completed')


@task
def provision_obor():
    log_green('running provision_obor')

    pool = Pool(processes=4)
    results = []

    for vm in [
        'vagrant-mesos-zk-01',
        'vagrant-mesos-zk-02',
        'vagrant-mesos-zk-03',
        'vagrant-mesos-slave'
    ]:
        results.append(pool.apipe(vagrant_provision_vm_with_retry, vm))

    for stream in results:
        stream.get()

    log_green('provision_obor completed')


@task
def vagrant_reload():
    log_green('running vagrant_reload')

    pool = Pool()
    results = []

    def flow(vm):
        vagrant_halt_vm_with_retry(vm)
        vagrant_up_vm_with_retry(vm)

    for vm in [
        'vagrant-mesos-zk-01',
        'vagrant-mesos-zk-02',
        'vagrant-mesos-zk-03',
        'vagrant-mesos-slave'
    ]:
        results.append(pool.apipe(flow, vm))

    for stream in results:
        stream.get()


@task
@retry(stop_max_attempt_number=3, wait_fixed=10000)
def clean():
    log_green('running clean')
    destroy_railtrack()
    for vm in [
        'vagrant-mesos-zk-01',
        'vagrant-mesos-zk-02',
        'vagrant-mesos-zk-03',
        'vagrant-mesos-slave'
    ]:
        local('VAGRANT_VAGRANTFILE=Vagrantfile.%s vagrant destroy -f' % vm)


@task
def config_json(config_yaml):
    """ generates the config.json for nixos """
    with open(config_yaml, 'r') as cfg_yaml:
        with open('config/config.json', 'w') as cfg_json:
            json.dump(
                yaml.load(cfg_yaml.read()),
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
    put('convert-os-to-nixos.sh', 'convert-os-to-nixos.sh', mode=0755)
    run('convert-os-to-nixos.sh', shell=True)


@task
@retry(stop_max_attempt_number=3, wait_fixed=10000)
def update():
    log_green('running update on {}'.format(env.host_string))
    local('rm -f {}/result'.format(env.host_string))
    with settings(
            warn_only=True,
            shell='/run/current-system/sw/bin/bash -l -c'
    ):
        rsync_project(
            remote_dir='/etc/nixos/',
            local_dir=env.host_string,
            delete=True,
            extra_opts='--rsync-path="sudo rsync"',
            default_opts='-chavzPq'
        )

    put('update.sh', 'update.sh', mode=0755)

    with settings(
            warn_only=True,
            shell='/run/current-system/sw/bin/bash -l -c'
    ):
        run('bash update.sh')


@task
def test_mesos_masters():
    execute(run_testinfra_against_mesos_masters)


@task
@retry(stop_max_attempt_number=6, wait_fixed=90000)
def run_testinfra_against_mesos_masters():
    local(
        "testinfra --connection=ssh --ssh-config=ssh.config "
        "-v -n 9  --hosts='{}' "
        "-m 'dnsmasq or docker or marathon_lb or marathon or mesos-dns or "
        "mesos_master or tincd or zookeeper or dns_resolution' "
        "tests".format(env.host_string)
    )


@task
def vagrant_test_mesos_masters():
    for vm in ['192.168.56.201',
               '192.168.56.202',
               '192.168.56.203']:
        with settings(host_string=vm):
            execute(test_mesos_masters)


@task
def test_mesos_slaves():
    execute(run_testinfra_against_mesos_slaves)


@task
@retry(stop_max_attempt_number=6, wait_fixed=90000)
def run_testinfra_against_mesos_slaves():
    local(
        "testinfra --connection=ssh --ssh-config=ssh.config "
        "-v -n 9 --hosts='{}' "
        "-m 'mesos_slave or tincd or docker or dns_resolution' "
        "tests".format(env.host_string)
    )


@task
def vagrant_test_mesos_slaves():
    for vm in ['192.168.56.204']:
        with settings(host_string=vm):
            execute(test_mesos_slaves)


@task
def destroy_railtrack():
    """ destroys Railtrack VMs """

    local('cd Railtrack && '
          'pip install -r requirements.txt')

    RAILTRACK_ENV = [
        "eval `ssh-agent`",
        "ssh-add Railtrack/key-pairs/*.priv"
    ]

    # local() doesn't support most context managers
    # so let's bake a local environment file and consume as a prefix()
    with open('shell_env', 'w') as f:
        for line in RAILTRACK_ENV:
            f.write(line + '\n')
    local('chmod +x shell_env')

    with settings(shell='/run/current-system/sw/bin/bash -l -c'):
        with prefix(". ./shell_env"):
            local("cd Railtrack && "
                  "fab -f tasks/fabfile.py clean")


@task
def spin_up_railtrack():
    """ deploys Railtrack locally """

    with settings(warn_only=True):
        local('git clone https://github.com/JeevesTakesOver/Railtrack.git')

    # make sure we are able to consume these key pairs
    local('chmod 700 Railtrack')
    local('chmod 400 Railtrack/key-pairs/*.priv')

    local('cd Railtrack && '
          'pip install -r requirements.txt')

    RAILTRACK_ENV = [
        "eval `ssh-agent`",
        "ssh-add Railtrack/key-pairs/*.priv"
    ]

    # local() doesn't support most context managers
    # so let's bake a local environment file and consume as a prefix()
    with open('shell_env', 'w') as f:
        for line in RAILTRACK_ENV:
            f.write(line + '\n')
    local('chmod +x shell_env')

    with settings(shell='/run/current-system/sw/bin/bash -l -c'):
        with prefix(". ./shell_env"):
            local("cd Railtrack && "
                  "fab -f tasks/fabfile.py step_01_create_hosts")


@task
def provision_railtrack():
    """ deploys Railtrack locally """

    local('cd Railtrack && '
          'pip install -r requirements.txt')

    RAILTRACK_ENV = [
        "eval `ssh-agent`",
        "ssh-add Railtrack/key-pairs/*.priv"
    ]

    # local() doesn't support most context managers
    # so let's bake a local environment file and consume as a prefix()
    with open('shell_env', 'w') as f:
        for line in RAILTRACK_ENV:
            f.write(line + '\n')
    local('chmod +x shell_env')

    with settings(shell='/run/current-system/sw/bin/bash -l -c'):
        with prefix(". ./shell_env"):
            local("cd Railtrack && "
                  "fab -f tasks/fabfile.py run_it acceptance_tests")


@task
def jenkins_build():
    """ runs a jenkins build """

    try:
        pool = Pool(processes=3)
        results = []
        # spin up and provision the Cluster
        results.append(pool.apipe(
            local, 'fab spin_up_obor provision_obor'))
        # spin up Railtrack, which is required for OBOR
        results.append(
            pool.apipe(
                local, 'fab spin_up_railtrack provision_railtrack'))

        for stream in results:
            stream.get()

        # reload after initial provision
        execute(vagrant_reload)

        sleep(180)

        # test all the things
        execute(vagrant_test_mesos_masters)
        execute(vagrant_test_mesos_slaves)

        # and now destroy Railtrack and mesos VMs
        execute(clean)
    except:  # noqa: E722 pylint: disable=bare-except
        log_red("jenkins_build() FAILED, aborting...")
        execute(clean)
        sys.exit(1)


"""
    ___main___
"""

env.connection_attempts = 10
env.timeout = 30
env.warn_only = False
env.disable_known_hosts = True
