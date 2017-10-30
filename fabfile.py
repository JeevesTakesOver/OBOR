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

from time import sleep

from fabric.api import task, env, execute, local, parallel, sudo
from fabric.operations import put, run
from fabric.contrib.project import rsync_project
from fabric.context_managers import settings, cd, shell_env, prefix

from bookshelf.api_v2.logging_helpers import log_green
from retrying import retry
import yaml
import json
import timeout_decorator
import shlex
from subprocess import Popen, PIPE



@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_up_vm_with_retry(vm):
    log_green('running vagrant_up_vm_with_retry')
    local('vagrant up %s' % vm) 

@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_reload_vm_with_retry(vm):
    log_green('running vagrant_reload_vm_with_retry')
    vagrant_halt_vm_with_retry(vm)
    vagrant_up_vm_with_retry(vm)


@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_run_with_retry(vm, command):
    log_green('running vagrant_run_with_retry')
    local('vagrant ssh %s -- %s' % (vm, command))

@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_halt_vm_with_retry(vm):
    log_green('running vagrant_halt_with_retry')
    local('vagrant halt %s' % vm)
    local('vagrant halt %s -f' % vm)

@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_provision_with_retry(vm):
    log_green('running vagrant_provision_with_retry')
    local('vagrant provision %s' % vm)

@retry(stop_max_attempt_number=3, wait_fixed=10000)
def restart_tinc_daemon_if_needed(vm):
    log_green('running restart_tinc_daemon_if_needeed')
    cmd = 'vagrant ssh %s -- ping -c1 www.google.com' % vm
    process = Popen(shlex.split(cmd), stdout=PIPE)
    process.communicate()
    exit_code = process.wait()

    if exit_code != 0:
        log_green('I am restarting tincd')
        # attempt to fix the most common issue, where tinc didn't receive
        # an ip address from dhcp
        local('vagrant ssh %s -- sudo systemctl restart tinc.core-vpn' % vm)
        log_green('sleeping for 90s')
        sleep(90)

    # and now fail for good if we still can't ping google
    local('vagrant ssh %s -- ping -c1 www.google.com' % vm)


@task
@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_ensure_tinc_network_is_operational():
    log_green('running vagrant_ensure_tinc_network_is_operational')
    # this will test if we can resolve google.com using
    # the tinc core DNS servers and if we can get out through the default gw
    for vm in [
        'vagrant-mesos-zk-01',
        'vagrant-mesos-zk-02',
        'vagrant-mesos-zk-03',
        'vagrant-mesos-slave'
    ]:
        restart_tinc_daemon_if_needed(vm)

        # and now fail for good if we still can't ping google
        local('vagrant ssh %s -- ping -c1 www.google.com' % vm)


@task
def spin_up_obor():
    log_green('running vagrant_up')
    for vm in [
        'vagrant-mesos-zk-01',
        'vagrant-mesos-zk-02',
        'vagrant-mesos-zk-03',
        'vagrant-mesos-slave']:
        vagrant_up_vm_with_retry(vm)


@task
def vagrant_reload():
    log_green('running vagrant_reload')
    for vm in [
        'vagrant-mesos-zk-01',
        'vagrant-mesos-zk-02',
        'vagrant-mesos-zk-03',
        'vagrant-mesos-slave']:
        vagrant_reload_vm_with_retry(vm)
        sleep(60)

@task
@retry(stop_max_attempt_number=3, wait_fixed=10000)
def vagrant_destroy():
    log_green('running vagrant_destroy')
    local('cd Railtrack && vagrant destroy -f')
    local('vagrant destroy -f')



@task
def vagrant_update():
    log_green('running vagrant_update')
    for vm, ip in [
        ('vagrant-mesos-zk-01', '192.168.56.201'),
        ('vagrant-mesos-zk-02', '192.168.56.202'),
        ('vagrant-mesos-zk-03', '192.168.56.203'),
        ('vagrant-mesos-slave', '192.168.56.204')
    ]:
        with settings(
            host_string=ip,
            user='vagrant',
            key_filename="~/.vagrant.d/insecure_private_key"
        ):
            execute(update)
            local('vagrant halt %s' % vm)
            local('vagrant up %s --no-provision' % vm)
            sleep(120)


@task
def vagrant_up_railtrack():
    log_green('running vagrant_up_railtrack')
    with cd('Railtrack'):
        with shell_env(
           'AWS_ACCESS_KEY_ID=VAGRANT',
           'AWS_SECRET_ACCESS_KEY=VAGRANT',
           'KEY_PAIR_NAME=vagrant-tinc-vpn',
           'KEY_FILENAME=$HOME/.vagrant.d/insecure_private_key',
           'TINC_KEY_FILENAME_CORE_NETWORK_01=key-pairs/core01.priv',
           'TINC_KEY_FILENAME_CORE_NETWORK_02=key-pairs/core02.priv',
           'TINC_KEY_FILENAME_CORE_NETWORK_03=key-pairs/core03.priv',
           'TINC_KEY_FILENAME_GIT2CONSUL=key-pairs/git2consul.priv',
           'CONFIG_YAML=config/config.yaml'
        ):
            local('fab -f tasks/fabfile.py '
                  'vagrant_up reset_consul it vagrant_reload')
            sleep(600)
            local('fab -f tasks/fabfile.py acceptance_tests')



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
        Since hardly any cloud providers have nixos images, we use 'nixos-infect'
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
@retry(stop_max_attempt_number=3, wait_fixed=60000)
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
@retry(stop_max_attempt_number=3, wait_fixed=60000)
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
def spin_up_railtrack():
    """ deploys Railtrack locally """
    local('vagrant plugin install vagrant-hostmanager')
    local('vagrant plugin install hostupdater')

    with settings(warn_only=True):
        local('git clone https://github.com/JeevesTakesOver/Railtrack.git')

    # make sure we are able to consume these key pairs
    local('chmod 700 Railtrack')
    local('chmod 400 Railtrack/key-pairs/*.priv')

    local('cd Railtrack && virtualenv venv && pip install -r requirements.txt')


    RAILTRACK_ENV = [
        "export AWS_ACCESS_KEY_ID=VAGRANT",
        "export AWS_SECRET_ACCESS_KEY=VAGRANT",
        "export KEY_PAIR_NAME=vagrant-tinc-vpn",
        "export KEY_FILENAME=$HOME/.vagrant.d/insecure_private_key",
        "export TINC_KEY_FILENAME_CORE_NETWORK_01=key-pairs/core01.priv",
        "export TINC_KEY_FILENAME_CORE_NETWORK_02=key-pairs/core02.priv",
        "export TINC_KEY_FILENAME_CORE_NETWORK_03=key-pairs/core03.priv",
        "export TINC_KEY_FILENAME_GIT2CONSUL=key-pairs/git2consul.priv",
        "export CONFIG_YAML=config/config.yaml",
        "eval `ssh-agent`",
        "ssh-add Railtrack/key-pairs/*.priv",
        ". venv/bin/activate"
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
                  "fab -f tasks/fabfile.py vagrant_up it vagrant_reload")
            sleep(600) # allow services to start properly
            local("cd Railtrack && "
                  "fab -f tasks/fabfile.py acceptance_tests")


@task
def jenkins_build():
    """ runs a jenkins build """

    try:
        # spin up Railtrack, which is required for OBOR
        execute(spin_up_railtrack)

        # spin up and provision the Cluster
        execute(spin_up_obor)

        # reload after initial provision
        execute(vagrant_reload)

        # allow the different services to recover after boot
        sleep(180)

        # check tinc network is operational
        execute(vagrant_ensure_tinc_network_is_operational)

        # allow the different services to recover
        sleep(180)

        # test all the things
        execute(vagrant_test_mesos_masters)
        execute(vagrant_test_mesos_slaves)

        # and now destroy Railtrack and mesos VMs
        execute(vagrant_destroy)
    except:
        # and now destroy Railtrack and mesos VMs
        execute(vagrant_destroy)
        sys.exit(1)



"""
    ___main___
"""

env.connection_attempts = 10
env.timeout = 30
env.warn_only = False
env.disable_known_hosts = True
