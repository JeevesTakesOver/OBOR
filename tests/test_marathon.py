import pytest

@pytest.mark.marathon
def test_marathon_is_running(Command):
    cmd = Command('sudo systemctl is-active marathon')
    assert cmd.rc == 0

    cmd = Command('sudo systemctl status marathon')
    assert cmd.rc == 0

@pytest.mark.marathon
def test_marathon_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled marathon')
    assert cmd.rc == 0

@pytest.mark.marathon
def test_marathon_is_listening_on_port_8080_on_tinc_interface(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*10.254.*:8080 *.*:.*LISTEN.*java'")
    assert cmd.rc == 0

