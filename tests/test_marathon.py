import pytest

@pytest.mark.marathon
def test_marathon_is_running(Command):
    cmd = Command('sudo systemctl is-active marathon')
    if cmd.rc != 0:
        raise AssertionError()

    cmd = Command('sudo systemctl status marathon')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.marathon
def test_marathon_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled marathon')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.marathon
def test_marathon_is_listening_on_port_8080_on_tinc_interface(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*10.254.*:8080 *.*:.*LISTEN.*java'")
    if cmd.rc != 0:
        raise AssertionError()

