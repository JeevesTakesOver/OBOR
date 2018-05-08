import pytest

@pytest.mark.mesos_consul
def test_mesos_consul_is_running(Command):
    cmd = Command('sudo systemctl is-active OBORmesos-consul')
    if cmd.rc != 0:
        raise AssertionError()

    cmd = Command('sudo systemctl status OBORmesos-consul')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.mesos_consul
def test_consul_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled OBORmesos-consul')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.mesos_consul
def test_consul_docker_service(Command):
    cmd = Command("sudo docker ps | grep 'mesos-consul' | grep 'Up'")
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.mesos_consul
def test_mesos_consul_dns_resolution(Command):
    cmd = Command("host leader.mesos.service.consul")
    if cmd.rc != 0:
        raise AssertionError()

