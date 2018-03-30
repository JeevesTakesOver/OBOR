import pytest

@pytest.mark.tincd
def test_tincd_is_running(Command):
    cmd = Command('sudo systemctl is-active tinc.core-vpn')
    if cmd.rc != 0:
        raise AssertionError()

    cmd = Command('sudo systemctl status tinc.core-vpn')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.tincd
def test_tincd_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled tinc.core-vpn')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.tincd
def test_tincd_is_listening_on_port_655(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*0.0.0.0*:655 *.*:.*LISTEN.*tincd'")
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.tincd
def test_tincd_should_ping_tinc_nodes(Command):
    for ip in ['10.254.0.1', '10.254.0.2', '10.254.0.3']:
        cmd = Command("ping -c 1 %s" % ip)
        if cmd.rc != 0:
            raise AssertionError()
