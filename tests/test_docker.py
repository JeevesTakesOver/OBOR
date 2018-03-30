import pytest

@pytest.mark.docker
def test_docker_is_running(Command):
    cmd = Command('sudo systemctl is-active docker')
    if cmd.rc != 0:
        raise AssertionError()

    cmd = Command('sudo systemctl status docker')
    if cmd.rc != 0:
        raise AssertionError()

@pytest.mark.docker
def test_docker_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled docker')
    if cmd.rc != 0:
        raise AssertionError()
