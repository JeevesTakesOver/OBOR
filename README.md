# OBOR
One Belt One Road is a Chinese government initiative to restablish a new Iron Silk Road using the Railway, linking China to Europe through China, Kazakhstan, Russia, Belorussia, Poland and Germany.  The first 18 train-car journey between both ends was achieved in April 2015 taking in total 13 days.


WIP !!!

The OBOR repository provides NixOS code to deploy a PaaS based on Mesos/Marathon
running on top of Railtrack (a globally distributed VPN).

I currently use this code to maintain my own Mesos Cluster. My cluster consists
of OVH cloud KVM instances for the mesos-masters, and different Bare-Metal providers
for the mesos-slaves, including some test desktop boxes I run at home.

All services are bound to VPN network interfaces and not exposed to the Internet.
The VPN is based on Railtrack (tinc based VPN).

This gives me a mixed on-premises and multi-cloud Mesos Cluster on top of a distributed VPN.


The fabfile in this repository is used to deploy and generate the required config.

Running :
``` 
fab config_json:config_yaml=<config/config.yaml.sample>
```

Will generate a config/config.json file based out a YAML config.


```
fab -H <ipaddress> convert-os-to-nixos 
```

will attempt to convert an ubuntu OS (from any cloud provider) into a NixOS OS.
This helps the issue of the lack of cloud providers currently offering a NixOS image.

```
fab -H <hostname> update
```

Will deploy NixOS according to our config on the target host.


```
fab -H <hostname> run_testinfra_against_mesos_masters
```

will run integration tests on the mesos-masters


```
fab -H <hostname> run_testinfra_against_mesos_slaves
```

will run integration tests on the mesos-slaves


```
fab jenkins_build()
```

Will deploy a local stack of Railtrack, and then proceed to deploy OBOR
on top of Railtrack using Vagrant.





