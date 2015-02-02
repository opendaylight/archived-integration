Everything required for building the Karaf OpenDaylight RPM.

Note that the currently supported version is Helium SR2.

## Building the RPM

The `build.sh` script is a helper for building the RPM. 

```
[fedora@dfarrell-rpm ~]$ ./build.sh 
<snip output of RPM building process>
RPM built!
Should be at: /home/fedora/rpmbuild/RPMS/noarch/opendaylight-0.2.1-5.fc20.noarch.rpm
```

## Working with the ODL RPM

The familiar RPM-related commands apply to the OpenDaylight RPM.

### Installing OpenDaylight via the RPM

```
# Note that there's nothing in /opt before the install
[fedora@dfarrell-rpm ~]$ ls /opt/
# Note that there are no opendaylight systemd files before install
[fedora@dfarrell-rpm ~]$ ls /usr/lib/systemd/system | grep -i opendaylight
# Install the ODL RPM
[fedora@dfarrell-rpm ~]$ sudo rpm -i /home/fedora/rpmbuild/RPMS/noarch/opendaylight-0.2.1-5.fc20.noarch.rpm
# Note that ODL is now installed in /opt
[fedora@dfarrell-rpm ~]$ ls /opt/
opendaylight-0.2.1
# Note that there's now a systemd .service file for ODL
[fedora@dfarrell-rpm ~]$ ls /usr/lib/systemd/system | grep -i opendaylight
opendaylight.service
```

The `install.sh` script is a helper for doing the install. Note that the script's path to the RPM may need to be configured.

### Uninstalling OpenDaylight via the RPM

```
# Note that ODL is installed in /opt/
[fedora@dfarrell-rpm ~]$ ls /opt/
opendaylight-0.2.1
# Note that there's a systemd .service file for ODL
[fedora@dfarrell-rpm ~]$ ls /usr/lib/systemd/system | grep -i opendaylight
opendaylight.service
# Uninstall the ODL RPM
[fedora@dfarrell-rpm ~]$ sudo rpm -e opendaylight-0.2.1
# Note that ODL has been removed from /opt/
[fedora@dfarrell-rpm ~]$ ls /opt/
# Note that the ODL systemd .service file has been removed
[fedora@dfarrell-rpm ~]$ ls /usr/lib/systemd/system | grep -i opendaylight
```

## Managing OpenDaylight via systemd

The OpenDaylight RPM ships with systemd support.

### Starting OpenDaylight via systemd

```
[fedora@dfarrell-rpm ~]$ sudo systemctl start opendaylight
[fedora@dfarrell-rpm ~]$ sudo systemctl status opendaylight
opendaylight.service - OpenDaylight SDN Controller
   Loaded: loaded (/usr/lib/systemd/system/opendaylight.service; disabled)
   Active: active (running) since Tue 2015-01-13 21:43:05 UTC; 14s ago
     Docs: https://wiki.opendaylight.org/view/Main_Page
           http://www.opendaylight.org/
 Main PID: 28731 (java)
   CGroup: /system.slice/opendaylight.service
           └─28731 java -server -Xms128M -Xmx2048m -XX:+UnlockDiagnosticVMOptions -XX:+UnsyncloadClass -XX:MaxPermSize=512m -Dcom.sun.manage...

Jan 13 21:43:14 dfarrell-rpm systemd[1]: Started OpenDaylight SDN Controller.
```

### Stopping OpenDaylight via systemd

```
[fedora@dfarrell-rpm ~]$ sudo systemctl stop opendaylight
[fedora@dfarrell-rpm ~]$ sudo systemctl status opendaylight
opendaylight.service - OpenDaylight SDN Controller
   Loaded: loaded (/usr/lib/systemd/system/opendaylight.service; disabled)
   Active: inactive (dead)
     Docs: https://wiki.opendaylight.org/view/Main_Page
           http://www.opendaylight.org/

Jan 27 19:08:11 dfarrell-rpm.os1.phx2.redhat.com systemd[1]: Starting OpenDaylight SDN Controller...
Jan 27 19:08:12 dfarrell-rpm.os1.phx2.redhat.com systemd[1]: Started OpenDaylight SDN Controller.
Jan 27 19:08:50 dfarrell-rpm.os1.phx2.redhat.com systemd[1]: Stopping OpenDaylight SDN Controller...
Jan 27 19:08:50 dfarrell-rpm.os1.phx2.redhat.com systemd[1]: Stopped OpenDaylight SDN Controller.
```

## Connecting to the Karaf shell

A few seconds after OpenDaylight is started, its Karaf shell will be accessible.

The `connect.sh` script is provided as an example of how to connect to the Karaf shell.

Additionally, here's an example of connecting manually (password: `karaf`):

```
[fedora@dfarrell-rpm ~]$ ssh -p 8101 -o StrictHostKeyChecking=no karaf@localhost
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
[fedora@dfarrell-rpm ~]$ 
```
