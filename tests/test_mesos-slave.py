import pytest

@pytest.mark.mesos_slave
def test_mesos_slave_is_running(Command):
    cmd = Command('systemctl is-active mesos-slave')
    assert cmd.rc == 0

    cmd = Command('systemctl status mesos-slave')
    assert cmd.rc == 0

@pytest.mark.mesos_slave
def test_mesos_slave_is_enabled(Command):
    cmd = Command('systemctl is-enabled mesos-slave')
    assert cmd.rc == 0

@pytest.mark.mesos_slave
def test_mesos_slave_is_listening_on_port_5051_on_tinc_interface(Command):
    cmd = Command("netstat -nltp | egrep -E 'tcp *.*169.254.*:5051 *.*:.*LISTEN.*mesos-slave'")
    assert cmd.rc == 0

