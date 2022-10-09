# ministra 5.6.9 changing from php:5-apache to ubuntu:20.04
FROM ubuntu:20.04

ADD ./etc/ /etc/
WORKDIR /

# Prepare

# Add repository for php7.0
RUN apt update
RUN apt install -y software-properties-common && add-apt-repository ppa:ondrej/php
RUN apt update && apt upgrade -y
# Remove php
# Ubuntu 20.04 has php7.2+ as the default version of PHP but ministra 5.6.9 can work with PHP version < 7.1 

RUN apt remove php* -y

# Install Apache2
RUN apt -y install apache2


# Missing devel packages for the PHP modules installation
RUN apt -y install apache2 nginx memcached curl mysql-server php7.0 php7.0-mysql \ 
php7.0-memcached  php7.0-curl php-pear php7.0-xml php7.0-mcrypt php7.0-zip \ 
php7.0-sqlite3 php7.0-imagick  php7.0-soap php7.0-intl php7.0-gettext \ 
php7.0-tidy php7.0-geoip nodejs systemd-sysv unzip \
wget nano


# Set php7.0 as default PHP.
RUN update-alternatives --set php /usr/bin/php7.0
RUN a2dismod php7.*
RUN a2enmod php7.0
# Enable Rewrite
RUN a2enmod rewrite

# Set PHP time zone
# RUN echo date.timezone="CET" > /usr/local/etc/php/conf.d/timezone.ini 
# Set the Server Timezone to EDT
RUN echo "Europe/Copenhagen" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

# Unpack, install
ADD ./src/ministra-5.6.9.zip /tmp/ministra-5.6.9.zip
RUN unzip /tmp/ministra-5.6.9.zip
RUN mv stalker_portal /var/www/html/stalker_portal/
RUN rm /tmp/ministra-5.6.9.zip

# Install NPM  2.5.11
RUN apt -y -u install npm
RUN npm install -g npm@2.15.11

# Install and configure apache cloudflare module
# RUN wget https://www.cloudflare.com/static/misc/mod_cloudflare/ubuntu/mod_cloudflare-trusty-amd64.latest.deb -O /tmp/mod_cloudflare-trusty-amd64.latest.deb
# RUN dpkg -i /tmp/mod_cloudflare-trusty-amd64.latest.deb
# RUN sed -i -e 's/CloudFlareRemoteIPTrustedProxy/CloudFlareRemoteIPTrustedProxy 172.16.0.0\/12 192.168.0.0\/16 10.0.0.0\/8/' /etc/apache2/mods-enabled/cloudflare.conf


# MySQL Settings
RUN echo 'sql_mode=""' >> /etc/mysql/mysql.conf.d/mysqld.cnf
RUN echo 'default_authentication_plugin=mysql_native_password' >> /etc/mysql/mysql.conf.d/mysqld.cnf   # For MySQL 8.X

RUN /etc/init.d/mysql restart

# PHP Settings
RUN echo "short_open_tag = On" >> /etc/php/7.0/apache2/php.ini

# Install PHING
RUN pear channel-discover pear.phing.info 
# RUN pear upgrade-all
RUN pear install --alldeps phing/phing-2.15.2   # Phing V2.16.4 has an issue with PHP7.0 and PHP7.1

# Copy custom.ini, build.xml.
ADD ./ministra_portal/ /var/www/html/stalker_portal

# install wget
RUN apt install -y wget

# Add IonCube Loaders
RUN mkdir /tmp/ioncube_install
WORKDIR /tmp/ioncube_install
RUN wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -O /tmp/ioncube_install/ioncube_loaders_lin_x86-64.tar.gz
RUN tar zxf /tmp/ioncube_install/ioncube_loaders_lin_x86-64.tar.gz
RUN php -i | grep extension_dir
RUN mv /tmp/ioncube_install/ioncube/ioncube_loader_lin_7.0.so /usr/lib/php/20151012/
RUN rm -rf /tmp/ioncube_install
RUN php --ini
RUN echo "zend_extension = /usr/lib/php/20151012/ioncube_loader_lin_7.0.so" >> /etc/php/7.0/cli/conf.d/00-ioncube.ini

# Fix Smart Launcher Applications
RUN mkdir /var/www/html/.npm
RUN chmod 777 /var/www/html/.npm

# Deploy stalker
RUN cd /var/www/html/stalker_portal/deploy/ && phing

# Configuring Nginx
RUN service nginx restart

RUN cp /lib/systemd/system/mysql.service /etc/systemd/system/
RUN echo "LimitNOFILE=infinity" >> /etc/systemd/system/mysql.service
RUN echo "LimitMEMLOCK=infinity" >> /etc/systemd/system/mysql.service
# RUN systemctl daemon-reload
# RUN systemctl restart mysql

# Finish installing broken packages
RUN apt-get install -f -y
RUN apt-get autoremove -y

EXPOSE 80

# CMD ["apache2-foreground"]

WORKDIR /var/www/html/

VOLUME ["/var/www/html/"]
