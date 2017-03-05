import pytest

@pytest.mark.docker
def test_docker_is_running(Command):
    cmd = Command('sudo systemctl is-active docker')
    assert cmd.rc == 0

    cmd = Command('sudo systemctl status docker')
    assert cmd.rc == 0

@pytest.mark.docker
def test_docker_is_enabled(Command):
    cmd = Command('sudo systemctl is-enabled docker')
    assert cmd.rc == 0


