import pytest

@pytest.mark.tincd
def test_tincd_is_running(Command):
    cmd = Command('sudo systemctl is-active tinc.core-vpn')
    assert cmd.rc == 0

    cmd = Command('sudo systemctl status tinc.core-vpn')
    assert cmd.rc == 0

@pytest.mark.tincd
def test_tincd_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled tinc.core-vpn')
    assert cmd.rc == 0

@pytest.mark.tincd
def test_tincd_is_listening_on_port_655(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*0.0.0.0*:655 *.*:.*LISTEN.*tincd'")
    assert cmd.rc == 0

@pytest.mark.tincd
def test_tincd_should_ping_tinc_nodes(Command):
    for ip in ['169.254.100.1', '169.254.100.2', '169.254.100.3']:
        cmd = Command("ping -c 1 %s" % ip)
        assert cmd.rc == 0
