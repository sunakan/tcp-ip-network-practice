.PHONY: up, rsync, halt, provision, detroy, ssh

up:
	vagrant up
	chmod 600 .vagrant/machines/*/virtualbox/private_key
rsync:
	vagrant rsync
provision:
	vagrant provision
halt:
	vagrant halt
destroy:
	vagrant destroy

test: rsync
	vagrant ssh tcpip-vm-0 -c 'cd codes && make ping'
	vagrant ssh tcpip-vm-0 -c 'cd codes && make ipaddressshow'
	vagrant ssh tcpip-vm-0 -c 'cd codes && make iprouteshow'

################################################################################
#
################################################################################
export VM_IP=192.168.3.10
define ssh-macro
	ssh \
		-o StrictHostKeyChecking=no \
		-i .vagrant/machines/tcpip-vm-0/virtualbox/private_key \
		vagrant@${VM_IP} $1
endef
ssh:
	$(call ssh-macro)

#rsync-linux:
#	rsync \
#		--rsh 'ssh -i .vagrant/machines/tcpip-vm-0/virtualbox/private_key -o StrictHostKeyChecking=no' \
#		--archive \
#		--compress \
#		--verbose \
#		--update \
#		./codes/ \
#		vagrant@${VM_IP}:/home/vagrant/codes/
