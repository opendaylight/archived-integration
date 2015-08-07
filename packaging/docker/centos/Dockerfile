# OpenDaylight Lithium 0.3.0 DockerFile
# Based on CentOS 
# https://registry.hub.docker.com/_/centos/
FROM centos:7
MAINTAINER OpenDaylight Project <info@opendaylight.org>

# Add repo for ODL
ADD opendaylight-3-candidate.repo /etc/yum.repos.d/

# Install required software including OpenDaylight
RUN yum update -y && yum install -y opendaylight

# Setup Ports:

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

# Start OpenDaylight
WORKDIR /opt/opendaylight
CMD ["./bin/karaf", "server"]
