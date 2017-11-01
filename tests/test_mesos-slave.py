import pytest

@pytest.mark.mesos_slave
def test_mesos_slave_is_running(Command):
    cmd = Command('sudo systemctl is-active mesos-slave')
    assert cmd.rc == 0

    cmd = Command('sudo systemctl status mesos-slave')
    assert cmd.rc == 0

@pytest.mark.mesos_slave
def test_mesos_slave_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled mesos-slave')
    assert cmd.rc == 0

@pytest.mark.mesos_slave
def test_mesos_slave_is_listening_on_port_5051_on_tinc_interface(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*10.254.*:5051 *.*:.*LISTEN.*mesos-slave'")
    assert cmd.rc == 0

