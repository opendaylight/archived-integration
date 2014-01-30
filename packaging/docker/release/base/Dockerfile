FROM ubuntu:12.04
MAINTAINER OpenDaylight Project <info@opendaylight.org>
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" >> /etc/apt/sources.list
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install openjdk-7-jre-headless unzip wget
RUN mkdir -p /opt/
RUN wget -q -O /opt/distribution.zip "https://nexus.opendaylight.org/service/local/artifact/maven/content?r=opendaylight.snapshot&g=org.opendaylight.integration&a=distributions-base&v=0.1.0-SNAPSHOT&c=osgipackage&p=zip"
RUN unzip /opt/*.zip -d /opt
RUN rm -rf /opt/*.zip
# Ports 
#    JMX:                  1088
#    Netconf:              1830
#    OSGi Console:         2400
#    Lisp Flow Mapping:    4342 # Service Provider Version
#    Internal Cluster RPC  5666
#    OpenFlow:             6633
#    ODL Clustering        7800
#    [default] Java Debug: 8000
#    ODL Web Portal:       8080
#    Netconf:              8383
#    ODL Clustering        12001
EXPOSE 1088 1830 2400 5666 6633 7800 8000 8080 8383 12001
WORKDIR /opt/opendaylight
ENTRYPOINT ["/opt/opendaylight/run.sh"]
