import pytest

@pytest.mark.mesos_dns
def test_mesos_dns_is_running(Command):
    cmd = Command('sudo systemctl is-active mesos-dns')
    assert cmd.rc == 0

    cmd = Command('sudo systemctl status mesos-dns')
    assert cmd.rc == 0

@pytest.mark.mesos_dns
def test_mesos_dns_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled mesos-dns')
    assert cmd.rc == 0

@pytest.mark.mesos_dns
def test_mesos_dns_is_listening_on_port_9153_on_tinc_interface(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*169.254.*:9153 *.*:.*LISTEN.*mesos-dns'")
    assert cmd.rc == 0

