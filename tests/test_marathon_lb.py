import pytest

@pytest.mark.marathon_lb
def test_marathon_lb_is_running(Command):
    cmd = Command('sudo systemctl is-active marathon-lb')
    assert cmd.rc == 0

    cmd = Command('sudo systemctl status marathon-lb')
    assert cmd.rc == 0

@pytest.mark.marathon_lb
def test_marathon_lb_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled marathon-lb')
    assert cmd.rc == 0


# marathon_lb should only be listening on the tinc vpn interface
# TODO: fix this
@pytest.mark.marathon_lb
def test_marathon_lb_is_listening_on_port_80(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*0.0.0.0:80 *.*:.*LISTEN.*haproxy'")
    assert cmd.rc == 0

@pytest.mark.marathon_lb
def test_marathon_lb_is_listening_on_port_443(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*0.0.0.0:443 *.*:.*LISTEN.*haproxy'")
    assert cmd.rc == 0

@pytest.mark.marathon_lb
def test_marathon_lb_is_listening_on_port_9090(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*0.0.0.0:9090 *.*:.*LISTEN.*haproxy'")
    assert cmd.rc == 0

@pytest.mark.marathon_lb
def test_marathon_lb_is_listening_on_port_9091(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*0.0.0.0:9091 *.*:.*LISTEN.*haproxy'")
    assert cmd.rc == 0

