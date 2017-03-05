import pytest

@pytest.mark.mesos_dns
def test_zookeeper_is_running(Command):
    cmd = Command('sudo systemctl is-active zookeeper')
    assert cmd.rc == 0

    cmd = Command('sudo systemctl status zookeeper')
    assert cmd.rc == 0

@pytest.mark.mesos_dns
def test_zookeeper_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled zookeeper')
    assert cmd.rc == 0

@pytest.mark.mesos_dns
def test_zookeeper_is_listening_on_port_2181_on_tinc_interface(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*169.254.*:2181 *.*:.*LISTEN.*java'")
    assert cmd.rc == 0

