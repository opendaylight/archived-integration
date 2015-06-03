# OpenDaylight Packer

[Packer][1] is a tool for automatically creating well-defined machine images of various types and optionally post-processing them into Vagrant base boxes, among other options.

OpenDaylight's current use-case for Packer is to build an ODL Vagrant base box, provisioned using upstream deployment/config tools. Reusing the logic of our configuration management tools nicely standardizes our deployment story, enabling good code reuse and separation of responsibilities. Providing an upstream Vagrant base box prevents all ODL consumers from duplicating ODL download, install and configuration logic, data transfer and computation in every Vagrantfile we create.

## Building ODL Images

After [installing Packer][2], build our ODL image with:

```
[~/integration/packaging/packer]$ packer build centos.json
```

We currently only support CentOS 7, output as a VirtualBox machine image, not packaged into a Vagrant box. Additional development is ongoing.

[1]: https://www.packer.io/
[2]: https://www.packer.io/intro/getting-started/setup.html
[3]: https://trello.com/c/OoS1aKaN/150-packaging-create-odl-vagrant-base-box
