import pytest

@pytest.mark.mesos_dns
def test_mesos_dns_is_running(Command):
    cmd = Command('sudo systemctl is-active OBORmesos-dns')
    if cmd.rc != 0:
        raise AssertionError()

    cmd = Command('sudo systemctl status OBORmesos-dns')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.mesos_dns
def test_mesos_dns_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled OBORmesos-dns')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.mesos_dns
def test_mesos_dns_is_listening_on_port_9153_on_tinc_interface(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*10.254.*:9153 *.*:.*LISTEN.*mesos-dns'")
    if cmd.rc != 0:
        raise AssertionError()

