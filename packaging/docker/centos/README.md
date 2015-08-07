# OpenDaylight Docker Image

The `Dockerfile` in this directory can be used to construct a Docker
image for the OpenDaylight SDN controller. The currently supported
OpenDaylight version is [Lithium][1]. Note that Lithium uses Karaf
to install features, and that the Docker image doesn't install any
features by default. You'll need to choose which features to install
based on your use-case.

## Pre-Built Docker Image

A pre-built OpenDaylight Lithium image is [available on DockerHub][2].

```
[~/sandbox]$ docker run -ti mgkwill/odl:0.3.0-centos ./bin/karaf
# ODL's Docker image will be downloaded if needed
<snip>
opendaylight-user@root>
```

## Building ODL's Docker Image

To manually build a Docker image from the included `Dockerfile`:

```
[~/integration/packaging/docker]$ docker build -t mgkwill/odl:0.3.0-centos .
[~/integration/packaging/docker]$ docker images | grep odl
mgkwill/odl    0.3.0    8e0fbf836106    18 hours ago        578.3 MB
```

Replace the tag name with one of your own choosing.

## Using the Image

To run commands against Dockerized OpenDaylight, use `docker run`. `WORKDIR`
is set to the root of ODL's install directory, `/opt/opendaylight`. Commands
passed to `docker run` should be relative to that path.

Additional information about running Docker images can be found [here][3].

### Ports

The OpenDaylight Docker image opens the full set of ports known to be used
by OpenDaylight generally. For most real-world sets of installed Karaf
features, only a small subset of these ports will actually be used by
ODL.

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

By default ports will be mapped to random ports on the host system. The
mappings can be discovered using the `docker ps` command.

If you wish to map these ports to specific ports on the host system, use
the `-p <host-port>:<container-port>` flag with `docker run`. Note that
[container linking][4] is generally recommend over hard-wiring ports with
`-p`.


[1]: https://www.opendaylight.org/software/downloads/lithium
[2]: https://registry.hub.docker.com/u/mgkwill/odl/
[3]: https://docs.docker.com/reference/run/
[4]: https://docs.docker.com/userguide/dockerlinks/
