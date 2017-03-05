import pytest

@pytest.mark.dnsmasq
def test_dnsmasq_is_running( Command):
    cmd = Command('sudo systemctl is-active dnsmasq')
    assert cmd.rc == 0

    cmd = Command('sudo systemctl status dnsmasq')
    assert cmd.rc == 0

@pytest.mark.dnsmasq
def test_dnsmasq_is_enabled( Command):
    cmd = Command('sudo systemctl is-enabled dnsmasq')
    assert cmd.rc == 0

@pytest.mark.dnsmasq
def test_dnsmasq_is_listening_on_port_53_on_localhost( Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*127.0.0.1:53 *.*:.*LISTEN.*dnsmasq'")
    assert cmd.rc == 0

@pytest.mark.dnsmasq
def test_dnsmasq_is_listening_on_port_53_on_tinc_interface( Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*169.254.*:53 *.*:.*LISTEN.*dnsmasq'")
    assert cmd.rc == 0

@pytest.mark.dnsmasq
def test_tinc_core_vpn_hostnames_are_resolvable( Command):
    for host in [
        'mesos-zk-01.tinc-core-vpn',
        'mesos-zk-02.tinc-core-vpn',
        'mesos-zk-03.tinc-core-vpn'
    ]:
        cmd = Command("host %s" % host)
        assert cmd.rc == 0

