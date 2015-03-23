Everything required for building the Karaf OpenDaylight RPM.

Note that the currently supported version is Helium SR3.

## Vagrant build environment

The included `Vagrantfile` provides a simple, but tested and known-working, build environment. We recommend using it when building an ODL RPM.

```
[~/integration/packaging/rpm]$ vagrant status
Current machine states:

default                   not created (virtualbox)
[~/integration/packaging/rpm]$ vagrant up
[~/integration/packaging/rpm]$ vagrant ssh
[vagrant@localhost vagrant]$ cd /vagrant/
[vagrant@localhost vagrant]$ ls
build.sh  connect.sh  install.sh  opendaylight.spec  README.md  Vagrantfile
```

## Building the RPM

The `build.sh` script is a helper for building the RPM. 

```
SRPM built!
Location: /home/vagrant/rpmbuild/SRPMS/opendaylight-0.2.3-1.fc20.src.rpm
Assuming you want to move RPM off Vagrant box
Also renaming RPM, not actually tagged as for FC20 target OS
cp /home/vagrant/rpmbuild/SRPMS/opendaylight-0.2.3-1.fc20.src.rpm /vagrant/opendaylight-0.2.3-1.src.rpm
RPM built!
Location: /home/vagrant/rpmbuild/RPMS/noarch/opendaylight-0.2.3-1.fc20.noarch.rpm
Assuming you want to move RPM off Vagrant box
Also renaming RPM, not actually tagged as for FC20 target OS
cp /home/vagrant/rpmbuild/RPMS/noarch/opendaylight-0.2.3-1.fc20.noarch.rpm /vagrant/opendaylight-0.2.3-1.noarch.rpm
```

## Working with the ODL RPM

The familiar RPM-related commands apply to the OpenDaylight RPM.

### Installing OpenDaylight via the RPM

The `install.sh` script is a helper for doing the install.

```
[vagrant@localhost vagrant]$ ./install.sh
Installing ODL from ./opendaylight-0.2.3-1.noarch.rpm
```

Here's a manual walk-through of the install and the resulting system changes.

```
# Note that there's nothing in /opt before the install
[vagrant@localhost vagrant]$ ls /opt/
# Note that there are no opendaylight systemd files before install
[vagrant@localhost vagrant]$ ls /usr/lib/systemd/system | grep -i opendaylight
# If you want to test the install in the provided build env, install Java
[vagrant@localhost vagrant]$ sudo yum install -y java
# Install the ODL RPM
[vagrant@localhost vagrant]$ sudo rpm -i opendaylight-0.2.3-1.noarch.rpm
# Note that ODL is now installed in /opt
[vagrant@localhost vagrant]$ ls /opt/
opendaylight
# Note that there's now a systemd .service file for ODL
[vagrant@localhost vagrant]$ ls /usr/lib/systemd/system | grep -i opendaylight
opendaylight.service
```

### Uninstalling OpenDaylight via the RPM

The `uninstall.sh` script is a helper for uninstalling ODL.

```
[vagrant@localhost vagrant]$ ./uninstall.sh
Uninstalling opendaylight-0.2.3
```

Here's a manual walk-through of the uninstall and the resulting system changes.

```
# Note that ODL is installed in /opt/
[vagrant@localhost vagrant]$ ls /opt/
opendaylight
# Note that there's a systemd .service file for ODL
[vagrant@localhost vagrant]$ ls /usr/lib/systemd/system | grep -i opendaylight
opendaylight.service
# Uninstall the ODL RPM
[vagrant@localhost vagrant]$ sudo rpm -e opendaylight-0.2.3
# Note that ODL has been removed from /opt/
[vagrant@localhost vagrant]$ ls /opt/
# Note that the ODL systemd .service file has been removed
[vagrant@localhost vagrant]$ ls /usr/lib/systemd/system | grep -i opendaylight
```

## Managing OpenDaylight via systemd

The OpenDaylight RPM ships with systemd support.

### Starting OpenDaylight via systemd

```
[vagrant@localhost vagrant]$ sudo systemctl start opendaylight
[vagrant@localhost vagrant]$ sudo systemctl status opendaylight
opendaylight.service - OpenDaylight SDN Controller
   Loaded: loaded (/usr/lib/systemd/system/opendaylight.service; disabled)
   Active: active (running) since Mon 2015-03-23 21:45:40 UTC; 34s ago
     Docs: https://wiki.opendaylight.org/view/Main_Page
           http://www.opendaylight.org/
  Process: 13839 ExecStart=/opt/opendaylight/bin/start (code=exited, status=0/SUCCESS)
 Main PID: 13846 (java)
   CGroup: /system.slice/opendaylight.service
           └─13846 java -server -Xms128M -Xmx2048m -XX:+UnlockDiagnosticVMOptions -X...

Mar 23 21:45:40 localhost.localdomain systemd[1]: Starting OpenDaylight SDN Control....
Mar 23 21:45:40 localhost.localdomain systemd[1]: Started OpenDaylight SDN Controller.
```

### Stopping OpenDaylight via systemd

```
[vagrant@localhost vagrant]$ sudo systemctl stop opendaylight
[vagrant@localhost vagrant]$ sudo systemctl status opendaylight
opendaylight.service - OpenDaylight SDN Controller
   Loaded: loaded (/usr/lib/systemd/system/opendaylight.service; disabled)
   Active: inactive (dead)
     Docs: https://wiki.opendaylight.org/view/Main_Page
           http://www.opendaylight.org/
# snip
```

## Connecting to the Karaf shell

A few seconds after OpenDaylight is started, its Karaf shell will be accessible.

The `connect.sh` script is provided as an example of how to connect to the Karaf shell.

```
[vagrant@localhost vagrant]$ ./connect.sh
Installing sshpass. It's used connecting non-interactively
# snip
opendaylight-user@root>
```

Additionally, here's an example of connecting manually (password: `karaf`):

```
[vagrant@localhost vagrant]$ ssh -p 8101 -o StrictHostKeyChecking=no karaf@localhost
Authenticated with partial success.
Password authentication
Password: 
                                                                                           
    ________                       ________                .__  .__       .__     __       
    \_____  \ ______   ____   ____ \______ \ _____  ___.__.|  | |__| ____ |  |___/  |_     
     /   |   \\____ \_/ __ \ /    \ |    |  \\__  \<   |  ||  | |  |/ ___\|  |  \   __\    
    /    |    \  |_> >  ___/|   |  \|    `   \/ __ \\___  ||  |_|  / /_/  >   Y  \  |      
    \_______  /   __/ \___  >___|  /_______  (____  / ____||____/__\___  /|___|  /__|      
            \/|__|        \/     \/        \/     \/\/            /_____/      \/          
                                                                                           

Hit '<tab>' for a list of available commands
and '[cmd] --help' for help on a specific command.
Hit '<ctrl-d>' or type 'system:shutdown' or 'logout' to shutdown OpenDaylight.

opendaylight-user@root>^D
Connection to localhost closed.
[vagrant@localhost vagrant]$
```
