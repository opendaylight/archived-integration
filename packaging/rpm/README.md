Everything required for building OpenDaylight's RPMs.

Note that the currently supported version is Lithium.

## Overview

The `opendaylight.spec` RPM spec file contains logic for packaging ODL's
tarball release artifact and a systemd service file into RPMs. The `build.sh`
helper script, when run in the simple Vagrant environment described by our
`Vagrantfile`, standardizes the build process. Additional helper scripts
are included for installing the noarch RPM, connecting to the ODL Karaf
shell and uninstalling ODL.

## Vagrant build environment

The included `Vagrantfile` provides a simple, but tested and known-working,
build environment. We recommend using it when building ODL's RPMs.

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
[~/integration/packaging/rpm]$ vagrant ssh
[vagrant@localhost ~]$ cd /vagrant/
[vagrant@localhost vagrant]$ ./build.sh
```

## Working with the ODL RPM

The familiar RPM-related commands apply to the OpenDaylight RPM.

### Installing OpenDaylight via a local RPM

The `install.sh` script is a helper for installing OpenDaylight from a
local RPM. It's intended for quick sanity checks after a `build.sh` run.

```
# After you've built the RPM via build.sh, still in the Vagrant enviroment
[vagrant@localhost vagrant]$ ./install.sh
```

Here's a manual walk-through of the install and the resulting system changes.

```
# Note that there's nothing in /opt before the install
[vagrant@localhost vagrant]$ ls /opt/
# Note that there are no ODL systemd files before the install
[vagrant@localhost vagrant]$ ls /usr/lib/systemd/system | grep -i opendaylight
# Install the ODL RPM
[vagrant@localhost vagrant]$ sudo rpm -i opendaylight-3.0.0-1.noarch.rpm
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
[vagrant@localhost vagrant]$ sudo rpm -e opendaylight-3.0.0
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
● opendaylight.service - OpenDaylight SDN Controller
   Loaded: loaded (/usr/lib/systemd/system/opendaylight.service; disabled)
   Active: active (running) since Tue 2015-07-14 21:09:30 UTC; 4s ago
     Docs: https://wiki.opendaylight.org/view/Main_Page
           http://www.opendaylight.org/
  Process: 18216 ExecStart=/opt/opendaylight/bin/start (code=exited, status=0/SUCCESS)
 Main PID: 18223 (java)
   CGroup: /system.slice/opendaylight.service
           └─18223 /usr/bin/java -Djava.security.properties=/opt/opendaylight/etc/odl.jav...

Jul 14 21:09:30 localhost.localdomain systemd[1]: Started OpenDaylight SDN Controller.
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
# Assuming you've started ODL
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
