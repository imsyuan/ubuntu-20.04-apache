FROM imsyuan/ubuntu-20.04:latest
MAINTAINER brian.wojtczak@1and1.co.uk
ARG DEBIAN_FRONTEND=noninteractive
ARG RPAF_VERSION=tags/v0.8.4
COPY files /
ENV SSL_KEY=/ssl/ssl.key \
    SSL_CERT=/ssl/ssl.crt \
    DOCUMENT_ROOT=html \
    MAXCONNECTIONSPERCHILD=500
RUN apt-get update
RUN apt-get install -o Dpkg::Options::=--force-confdef -y apache2 cronolog build-essential git apache2-dev poppler-utils libapache2-mod-rpaf
RUN mkdir /tmp/mod_rpaf
RUN git clone https://github.com/gnif/mod_rpaf.git /tmp/mod_rpaf
RUN update-alternatives --install /bin/sh sh /bin/bash 100
RUN cd /tmp/mod_rpaf && git checkout $RPAF_VERSION
RUN cd /tmp/mod_rpaf && ls -la
RUN cd /tmp/mod_rpaf && make
RUN cd /tmp/mod_rpaf && make install
RUN mkdir -p /var/lock/apache2 && mkdir -p /var/run/apache2
RUN chmod -R 777 /var/log/apache2 /var/lock/apache2 /var/run/apache2 \
                   /etc/apache2/sites-* /etc/apache2/mods-* /etc/apache2/conf-* \
                   /var/www
RUN chmod 666 /etc/apache2/ports.conf
RUN echo "SSLProtocol ALL -SSLv2 -SSLv3" >> /etc/apache2/apache2.conf
RUN echo 'MaxConnectionsPerChild ${MAXCONNECTIONSPERCHILD}' >> /etc/apache2/apache2.conf
RUN sed -i -e 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf
RUN sed -i -e 's/Listen 443/#Listen 8443/g' /etc/apache2/ports.conf
RUN echo "Listen 8081" >> /etc/apache2/ports.conf
RUN a2enmod deflate
RUN a2enmod rewrite
RUN a2enmod ssl
RUN a2enmod headers
RUN a2enmod macro
RUN a2enmod rpaf
RUN a2enmod cgi
RUN a2enmod expires
RUN a2enmod include
RUN a2disconf other-vhosts-access-log
RUN a2enconf vhosts-logging
RUN apt-get -y autoremove build-essential apache2-dev git
RUN rm -rf /tmp/mod_rpaf
RUN rm -rf /var/lib/apt/lists/*

EXPOSE 8080 8443