import pytest

@pytest.mark.zookeeper
def test_zookeeper_is_running(Command):
    cmd = Command('sudo systemctl is-active OBORzookeeper')
    if cmd.rc != 0:
        raise AssertionError()

    cmd = Command('sudo systemctl status OBORzookeeper')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.zookeeper
def test_zookeeper_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled OBORzookeeper')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.zookeeper
def test_zookeeper_is_listening_on_port_2181_on_tinc_interface(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*10.254.*:2181 *.*:.*LISTEN.*java'")
    if cmd.rc != 0:
        raise AssertionError()

