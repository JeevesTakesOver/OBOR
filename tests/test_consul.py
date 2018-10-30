import pytest

@pytest.mark.consul
def test_consul_is_running(Command):
    cmd = Command('sudo systemctl is-active OBORconsul')
    if cmd.rc != 0:
        raise AssertionError()

    cmd = Command('sudo systemctl status OBORconsul')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.consul
def test_consul_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled OBORconsul')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.consul
def test_consul_is_listening_on_port_8301_on_tinc_interface(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*10.254.*:8301 *.*:.*LISTEN.*'")
    if cmd.rc != 0:
        raise AssertionError()

