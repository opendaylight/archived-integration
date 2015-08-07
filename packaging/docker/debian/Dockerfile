# OpenDaylight Lithium 0.3.0 DockerFile
# Based on Debian
# https://registry.hub.docker.com/_/debian/
FROM debian:7
MAINTAINER OpenDaylight Project <info@opendaylight.org>

# Install required software (170MB)
RUN apt-get update && apt-get install -y openjdk-7-jre-headless wget

# Download and install ODL
WORKDIR /opt
RUN mkdir opendaylight
# Doing all of these in one step reduces the resulting image size by 229MB
RUN wget -q "https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.3.0-Lithium/distribution-karaf-0.3.0-Lithium.tar.gz" && \
    tar -xf distribution-karaf-0.3.0-Lithium.tar.gz -C opendaylight --strip-components=1 && \
    rm distribution-karaf-0.3.0-Lithium.tar.gz

# TODO: Verify that these are all of the ODL Lithium ports
# Ports
# 162 - SNMP4SDN (only when started as root)
# 179 - BGP
# 1088 - JMX access
# 1790 - BGP/PCEP
# 1830 - Netconf
# 2400 - OSGi console
# 2550 - ODL Clustering
# 2551 - ODL Clustering
# 2552 - ODL Clustering
# 4189 - PCEP
# 4342 - Lisp Flow Mapping
# 5005 - JConsole
# 5666 - ODL Internal clustering RPC
# 6633 - OpenFlow
# 6640 - OVSDB
# 6653 - OpenFlow
# 7800 - ODL Clustering
# 8000 - Java debug access
# 8080 - OpenDaylight web portal
# 8101 - KarafSSH
# 8181 - MD-SAL RESTConf and DLUX
# 8383 - Netconf
# 12001 - ODL Clustering
EXPOSE 162 179 1088 1790 1830 2400 2550 2551 2552 4189 4342 5005 5666 6633 6640 6653 7800 8000 8080 8101 8181 8383 12001

WORKDIR /opt/opendaylight
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64/jre
CMD ["./bin/karaf", "server"]
