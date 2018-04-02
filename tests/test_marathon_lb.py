import pytest

@pytest.mark.marathon_lb
def test_marathon_lb_is_running(Command):
    cmd = Command('sudo systemctl is-active OBORmarathon-lb')
    if cmd.rc != 0:
        raise AssertionError()

    cmd = Command('sudo systemctl status OBORmarathon-lb')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.marathon_lb
def test_marathon_lb_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled OBORmarathon-lb')
    if cmd.rc != 0:
        raise AssertionError()


# marathon_lb should only be listening on the tinc vpn interface
# TODO: fix this
@pytest.mark.marathon_lb
def test_marathon_lb_is_listening_on_port_80(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*0.0.0.0:80 *.*:.*LISTEN.*haproxy'")
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.marathon_lb
def test_marathon_lb_is_listening_on_port_443(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*0.0.0.0:443 *.*:.*LISTEN.*haproxy'")
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.marathon_lb
def test_marathon_lb_is_listening_on_port_9090(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*0.0.0.0:9090 *.*:.*LISTEN.*haproxy'")
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.marathon_lb
def test_marathon_lb_is_listening_on_port_9091(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*0.0.0.0:9091 *.*:.*LISTEN.*haproxy'")
    if cmd.rc != 0:
        raise AssertionError()

