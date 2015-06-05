# OpenDaylight Packer

[Packer][1] is a tool for automatically creating well-defined machine images of various types and optionally post-processing them into Vagrant base boxes, among other options.

OpenDaylight's current use-case for Packer is to build an ODL Vagrant base box, provisioned using upstream deployment/config tools. Reusing the logic of our configuration management tools nicely standardizes our deployment story, enabling good code reuse and separation of responsibilities. Providing an upstream Vagrant base box prevents all ODL consumers from duplicating ODL download, install and configuration logic, data transfer and computation in every Vagrantfile we create.

We currently only support CentOS 7, output as a VirtualBox machine image, not packaged into a Vagrant box. Additional development is ongoing.

## Building an ODL Vagrant Base Box

After [installing Packer][2], build our ODL Vagrant base box with:

```
[~/integration/packaging/packer]$ packer build centos.json
```

This will download and verify a fresh CentOS 7.1 Minimal ISO, use a Kickstart template to automate a minimal install against a VirtualBox host, run a post-install shell provisioner to configure the VM for use as a Vagrant base box and finally export, compress and package it as a Vagrant base box.

```
<snip>
Build 'virtualbox-iso' finished.

==> Builds finished. The artifacts of successful builds are:
--> virtualbox-iso: 'virtualbox' provider box: opendaylight-centos-7.1.box
[~/integration/packaging/packer]$ ls -lh opendaylight-centos-7.1.box
-rw-rw-r--. 1 daniel daniel 532M Jun  5 00:32 opendaylight-centos-7.1.box
```

Import the local box into Vagrant with:

```
[~/integration/packaging/packer]$ vagrant box add --name "opendaylight" opendaylight-centos-7.1.box --force
==> box: Adding box 'opendaylight' (v0) for provider:
    box: Downloading: file:///home/daniel/integration/packaging/packer/opendaylight-centos-7.1.box
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


[1]: https://www.packer.io/
[2]: https://www.packer.io/intro/getting-started/setup.html
[3]: https://trello.com/c/OoS1aKaN/150-packaging-create-odl-vagrant-base-box
