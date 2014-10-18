### OpenDaylight Docker Images
The `Dockerfile` in this directory can be used to construct a Docker image for the OpenDaylight SDN controller. The current OpenDaylight version is [Helium](http://www.opendaylight.org/software/downloads/helium). Note that Helium uses Karaf to install features, and that the Docker image doesn't install any features by default. You'll need to choose which features to install based on your use-case.

### OpenDaylight on DockerHub
A pre-built OpenDaylight Helium image is available on DockerHub. You can find it with `docker search opendaylight`:

TODO: Show example once ODL Helium image is on DockerHub

You can then pull it to your local system with `docker pull opendaylight/helium`:

TODO: Show example once ODL Helium image is on DockerHub

### Using the Image
To run commands against Dockerized OpenDaylight, use `docker run`. `WORKDIR` is set to the root of ODL's install directory, `/opt/opendaylight`. Commands passed to `docker run` should be relative to that path.

Additional information about running Docker images can be found [here](https://docs.docker.com/reference/run/).

### Ports
OpenDaylight Helium will expose subsets of the following ports. The actual set of exposed ports for a given controller is determined by the features installed via Karaf.

TODO: Verify that these are all of the ODL Helium ports and no extra

* 162 - SNMP4SDN (only when started as root)
* 179 - BGP
* 1088 - JMX access
* 1790 - BGP/PCEP
* 1830 - Netconf
* 2400 - OSGi console
* 2550 - ODL Clustering
* 2551 - ODL Clustering
* 2552 - ODL Clustering
* 4189 - PCEP
* 4342 - Lisp Flow Mapping
* 5005 - JConsole
* 5666 - ODL Internal clustering RPC
* 6633 - OpenFlow
* 6640 - OVSDB
* 6653 - OpenFlow
* 7800 - ODL Clustering
* 8000 - Java debug access
* 8080 - OpenDaylight web portal
* 8101 - KarafSSH
* 8181 - MD-SAL RESTConf and DLUX
* 8383 - Netconf
* 12001 - ODL Clustering

By default these ports will be mapped to random ports on the host system. The mappings can be discovered using the `docker ps` command. 

If you wish to map these ports to specific ports on the host system, use the `-p <host-port>:<container-port>` flag with `docker run`. Note that [container linking](https://docs.docker.com/userguide/dockerlinks/) is generally recommend over hard-wiring ports with `-p`.
