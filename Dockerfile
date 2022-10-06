# ministra 5.6.9 should work with PHP7, changing this line from 5-apache to 7.0-apache
FROM php:7.0-apache

ADD ./etc/ /etc/
WORKDIR /

# Prepare
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install -y -u apt-utils unzip mysql-client nodejs systemd-sysv wget curl cron

# Missing devel packages for the PHP modules installation
RUN apt-get install -y icu-devtools libxml2-dev
RUN apt-get install -y libcurl4-nss-dev libtidy-dev
RUN apt-get install -y libpng-dev libicu-dev

# Install PHP modules
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install soap
RUN docker-php-ext-install intl
RUN docker-php-ext-install gettext
RUN docker-php-ext-install curl
RUN docker-php-ext-install tidy
RUN docker-php-ext-install gd
RUN docker-php-ext-install pdo_mysql

# Set PHP time zone
RUN echo date.timezone="UTC" > /usr/local/etc/php/conf.d/timezone.ini 

# Unpack, install
ADD ./src/ministra-5.6.9.zip /tmp/ministra-5.6.9.zip
RUN unzip /tmp/ministra-5.6.9.zip
RUN mv stalker_portal /var/www/html/stalker_portal/
RUN rm /tmp/ministra-5.6.9.zip

# Install and configure apache cloudflare module
# RUN wget https://www.cloudflare.com/static/misc/mod_cloudflare/ubuntu/mod_cloudflare-trusty-amd64.latest.deb -O /tmp/mod_cloudflare-trusty-amd64.latest.deb
# RUN dpkg -i /tmp/mod_cloudflare-trusty-amd64.latest.deb
# RUN sed -i -e 's/CloudFlareRemoteIPTrustedProxy/CloudFlareRemoteIPTrustedProxy 172.16.0.0\/12 192.168.0.0\/16 10.0.0.0\/8/' /etc/apache2/mods-enabled/cloudflare.conf

# Enable Rewrite
RUN a2enmod rewrite

# Install PHING
RUN pear channel-discover pear.phing.info 
# RUN pear upgrade-all
RUN pear install --alldeps phing/phing-2.15.2   # Phing V2.16.4 has an issue with PHP7.0 and PHP7.1

# Copy custom.ini, build.xml.
ADD ./ministra_portal/ /var/www/html/stalker_portal

# Add IonCube Loaders
RUN mkdir /tmp/ioncube_install
WORKDIR /tmp/ioncube_install
RUN wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -O /tmp/ioncube_install/ioncube_loaders_lin_x86-64.tar.gz
RUN tar zxf /tmp/ioncube_install/ioncube_loaders_lin_x86-64.tar.gz
RUN mv /tmp/ioncube_install/ioncube/ioncube_loader_lin_7.0.so /usr/local/lib/php/extensions/no-debug-non-zts-20151012/
RUN rm -rf /tmp/ioncube_install
RUN echo "zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20151012/ioncube_loader_lin_7.0.so" >> /usr/local/etc/php/conf.d/00-ioncube.ini

# Fix Smart Launcher Applications
RUN mkdir /var/www/html/.npm
RUN chmod 777 /var/www/html/.npm

# Deploy stalker
RUN cd /var/www/html/stalker_portal/deploy/ && phing

# Finish installing broken packages
RUN apt-get install -f -y
RUN apt-get autoremove -y

EXPOSE 80

CMD ["apache2-foreground"]

WORKDIR /var/www/html/

VOLUME ["/var/www/html/"]
