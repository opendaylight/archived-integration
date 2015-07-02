# OpenDaylight Packer

[Packer][1] is a tool for automatically creating VM and container images,
configuring them and post-processing them into standard output formats.

We currently build OpenDaylight's Vagrant base box and Docker image via Packer.

## Building an ODL Vagrant Base Box

You'll need to [install Packer][2], of course.

You can now build our ODL Vagrant base box with:

```
[~/integration/packaging/packer]$ packer build -var-file=packer_vars.json centos.json
```

This will:

* Download and verify a fresh CentOS 1503 Minimal ISO.
* Use a Kickstart template to automate a minimal install against
  a VirtualBox host.
* Run a post-install shell provisioner to do VirtualBox, Vagrant
  and Ansible-specific config.
* Install OpenDaylight using its [Ansible role][4].
* Export, compress and package the VM as a Vagrant base box.

```
<snip>
Build 'virtualbox-iso' finished.

==> Builds finished. The artifacts of successful builds are:
--> virtualbox-iso: 'virtualbox' provider box: opendaylight-2.3.0-centos-1503.box
[~/integration/packaging/packer]$ ls -lh opendaylight-2.3.0-centos-1503.box
-rw-rw-r--. 1 daniel daniel 1.1G Jun  9 01:13 opendaylight-2.3.0-centos-1503.box
```

Import the local box into Vagrant with:

```
[~/integration/packaging/packer]$ vagrant box add --name "opendaylight" opendaylight-2.3.0-centos-1503.box --force
==> box: Adding box 'opendaylight' (v0) for provider:
    box: Downloading: file:///home/daniel/integration/packaging/packer/opendaylight-2.3.0-centos-1503.box
==> box: Successfully added box 'opendaylight' (v0) for 'virtualbox'!
```

To connect to your new box, you'll need a trivial Vagrantfile:

```
[~/integration/packaging/packer]$ vagrant init -m opendaylight
A `Vagrantfile` has been placed in this directory.<snip>
[~/integration/packaging/packer]$ cat Vagrantfile
Vagrant.configure(2) do |config|
  config.vm.box = "opendaylight"
end
[~/integration/packaging/packer]$ vagrant ssh
<snip>
```

OpenDaylight will already be installed and running:

```
[vagrant@localhost ~]$ sudo systemctl is-active opendaylight
active
```

## Pre-Built ODL Base Box

While we'd eventually like to provide more official places to host ODL's
base boxes, all of this is new and under active development. For now,
you can consume the product of this Packer build configuration via
Atlas (previously called be VagrantCloud), the de facto box hosting
service at the moment. It's at [dfarrell07/opendaylight][5] for now, but
of course we'd like to transfer it to an official OpenDaylight account
eventually (a Help Desk ticket has been submitted).

```
[~/sandbox]$ vagrant init -m dfarrell07/opendaylight
[~/sandbox]$ cat Vagrantfile
Vagrant.configure(2) do |config|
  config.vm.box = "dfarrell07/opendaylight"
end
[~/sandbox]$ vagrant up
# Downloads box from Atlas
# Boots box
[~/sandbox]$ vagrant ssh
[vagrant@localhost ~]$ sudo systemctl is-active opendaylight
active
[vagrant@localhost ~]$ /opt/opendaylight/bin/client
<snip>
opendaylight-user@root>
```


[1]: https://www.packer.io/
[2]: https://www.packer.io/intro/getting-started/setup.html
[3]: https://trello.com/c/OoS1aKaN/150-packaging-create-odl-vagrant-base-box
[4]: https://github.com/dfarrell07/ansible-opendaylight
[5]: https://atlas.hashicorp.com/dfarrell07/boxes/opendaylight
