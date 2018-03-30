import pytest

@pytest.mark.dns_resolution
def test_tinc_core_vpn_hostnames_are_resolvable( Command):
    for host in [
        'mesos-zk-01.tinc-core-vpn',
        'mesos-zk-02.tinc-core-vpn',
        'mesos-zk-03.tinc-core-vpn'
    ]:
        cmd = Command("host %s" % host)
        if cmd.rc != 0:
            raise AssertionError()

@pytest.mark.dns_resolution
def test_mesos_dns_should_resolve_leader_mesos(Command):
    cmd = Command("nslookup leader.mesos")
    if cmd.rc != 0:
        raise AssertionError()
