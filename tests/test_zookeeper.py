import pytest

@pytest.mark.mesos_dns
def test_zookeeper_is_running(Command):
    cmd = Command('sudo systemctl is-active zookeeper')
    if cmd.rc != 0:
        raise AssertionError()

    cmd = Command('sudo systemctl status zookeeper')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.mesos_dns
def test_zookeeper_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled zookeeper')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.mesos_dns
def test_zookeeper_is_listening_on_port_2181_on_tinc_interface(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*10.254.*:2181 *.*:.*LISTEN.*java'")
    if cmd.rc != 0:
        raise AssertionError()

