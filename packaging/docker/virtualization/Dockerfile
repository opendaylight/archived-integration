FROM ubuntu:12.04
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" >> /etc/apt/sources.list
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install openjdk-7-jre-headless unzip
RUN mkdir -p /opt/
ADD target/dist /opt/
RUN unzip /opt/*.zip -d /opt
RUN rm -rf /opt/*.zip
# Ports 
#    JMX:                  1088
#    Netconf:              1830
#    OSGi Console:         2400
#    OpenFlow:             6633
#    [default] Java Debug: 8000
#    ODL Web Portal:       8080
#    Netconf:              8383
EXPOSE 1088 1830 2400 6633 8000 8080 8383
WORKDIR /opt/opendaylight
ENTRYPOINT ["/opt/opendaylight/run.sh"]