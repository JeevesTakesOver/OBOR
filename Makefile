help:
	echo "make config=<config/config.yaml> config_json"
	echo "make target=<hostname> convert-os-to-nixos"
	echo "make target=<hostname> update"
	echo
	echo "where <hostname> should match the directory name containing the"
	echo "nix code to provision."


# converts most Cloud instances to nixos automatically.
# Since hardly any cloud providers have nixos images, we use 'nixos-infect'
# to recycle an existing OS into a nixos box.
.ONESHELL:
convert-os-to-nixos:
	scp convert-os-to-nixos.sh $(target):convert-os-to-nixos.sh 
	ssh $(target) bash convert-os-to-nixos.sh || echo


# update will apply our nixos configuration to the box
.ONESHELL:
update:
	rm -f $(target)/result
	rsync -chavzP --rsync-path="sudo rsync" --stats --delete $(target)/ common config $(target):/etc/nixos/
	scp update.sh $(target):update.sh
	ssh $(target) bash update.sh

# tests for our mesos master
test_mesos_masters:
	testinfra --connection=ssh -v -n 9  --hosts='$(target)' -m 'dnsmasq or docker or marathon_lb or marathon or mesos-dns or mesos_master or tincd or zookeeper or dns_resolution' tests

# tests for our mesos slave
test_mesos_slaves:
	testinfra --connection=ssh -v -n 9  --hosts='$(target)' -m 'mesos_slave or tincd or docker or dns_resolution' tests

# restart all the services on our mesos master
.ONESHELL:
restart-master-services:
	for ta in $(target)
	do
		echo "restarting tinc.core-vpn on $$ta"
		ssh $$ta systemctl restart tinc.core-vpn
		ssh $$ta systemctl status tinc.core-vpn
		echo "sleeping for 30 seconds..."
		sleep 30
	done
	for ta in $(target)
	do
		echo "restarting zookeeper on $$ta"
		ssh $$ta systemctl restart zookeeper
		ssh $$ta systemctl status zookeeper
		echo "sleeping for 30 seconds..."
		sleep 30
	done
	for ta in $(target)
	do
		echo "restarting consul on $$ta"
		ssh $$ta systemctl restart consul
		ssh $$ta systemctl status consul
		echo "sleeping for 30 seconds..."
		sleep 30
	done
	for ta in $(target)
	do
		echo "restarting mesos-dns on $$ta"
		ssh $$ta systemctl restart mesos-dns
		ssh $$ta systemctl status mesos-dns
		echo "sleeping for 30 seconds..."
		sleep 30
	done
	for ta in $(target)
	do
		echo "restarting dnsmasq on $$ta"
		ssh $$ta systemctl restart dnsmasq
		ssh $$ta systemctl status dnsmasq
		echo "sleeping for 30 seconds..."
		sleep 30
	done
	for ta in $(target)
	do
		echo "restarting mesos-master on $$ta"
		ssh $$ta systemctl restart mesos-master
		ssh $$ta systemctl status mesos-master
		echo "sleeping for 30 seconds..."
		sleep 30
	done
	for ta in $(target)
	do
		echo "restarting marathon on $$ta"
		ssh $$ta systemctl restart marathon
		ssh $$ta systemctl status marathon
		echo "sleeping for 30 seconds..."
		sleep 30
	done
	for ta in $(target)
	do
		ssh $$ta systemctl restart marathon-lb
		ssh $$ta systemctl status marathon-lb
		echo "sleeping for 30 seconds..."
		sleep 30
	done

# restart all the services on our mesos slave
.ONESHELL:
restart-slave-services:
	for ta in $(target)
	do
		echo "restarting tinc.core-vpn on $$ta"
		ssh $$ta systemctl restart tinc.core-vpn
		ssh $$ta systemctl status tinc.core-vpn
		echo "sleeping for 30 seconds..."
		sleep 30
	done
	for ta in $(target)
	do
		echo "restarting mesos-slave on $$ta"
		ssh $$ta systemctl restart mesos-slave
		ssh $$ta systemctl status mesos-slave
		echo "sleeping for 30 seconds..."
		sleep 30
	done

# generates the config.json file used by the nixos configs from a config.yaml
# file.
config_json:
	python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < $(config) > config/config.json


# Deploys a local Railtrack VPN using vagrant
.ONESHELL:
deploy_railtrack:
	git clone https://github.com/JeevesTakesOver/Railtrack
	cd Railtrack
	vagrant plugin install vagrant-hostmanager
	vagrant plugin install hostupdater
	export AWS_ACCESS_KEY_ID=VAGRANT
	export AWS_SECRET_ACCESS_KEY=VAGRANT
	export KEY_PAIR_NAME=vagrant-tinc-vpn
	export KEY_FILENAME=$HOME/.vagrant.d/insecure_private_key
	export TINC_KEY_FILENAME_CORE_NETWORK_01=key-pairs/core01.priv
	export TINC_KEY_FILENAME_CORE_NETWORK_02=key-pairs/core02.priv
	export TINC_KEY_FILENAME_CORE_NETWORK_03=key-pairs/core03.priv
	export TINC_KEY_FILENAME_GIT2CONSUL=key-pairs/git2consul.priv
	export CONFIG_YAML=config/config.yaml
	make venv
	make up
	make it
	make acceptance_tests

# restart mesos-dns:
.ONESHELL:
restart-mesos-dns:
	for ta in $(target)
	do
		echo "restarting mesos-dns on $$ta"
		ssh $$ta systemctl restart mesos-dns
		ssh $$ta systemctl status mesos-dns
		echo "sleeping for 30 seconds..."
		sleep 30
	done


.ONESHELL:
restart-marathon:
	for ta in $(target)
	do
		echo "stop marathon on $$ta"
		ssh $$ta systemctl stop marathon
	done
	echo "sleeping for 30 seconds..."
	sleep 30
	for ta in $(target)
	do
		echo "starting marathon on $$ta"
		ssh $$ta systemctl start marathon
	done
