import pytest

@pytest.mark.mesos_master
def test_mesos_master_is_running(Command):
    cmd = Command('sudo systemctl is-active mesos-master')
    assert cmd.rc == 0

    cmd = Command('sudo systemctl status mesos-master')
    assert cmd.rc == 0

@pytest.mark.mesos_master
def test_mesos_master_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled mesos-master')
    assert cmd.rc == 0

@pytest.mark.mesos_master
def test_mesos_master_is_listening_on_port_5050_on_tinc_interface(Command):
    cmd = Command("sudo netstat -nltp | egrep -E 'tcp *.*169.254.*:5050 *.*:.*LISTEN.*mesos-master'")
    assert cmd.rc == 0

