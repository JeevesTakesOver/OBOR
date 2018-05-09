import pytest

@pytest.mark.traefik
def test_traefik_is_running(Command):
    cmd = Command('sudo systemctl is-active OBORtraefik')
    if cmd.rc != 0:
        raise AssertionError()

    cmd = Command('sudo systemctl status OBORtraefik')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.traefik
def test_consul_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled OBORtraefik')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.traefik
def test_consul_docker_service(Command):
    cmd = Command("sudo docker ps | grep 'traefik' | grep 'Up'")
    if cmd.rc != 0:
        raise AssertionError()

