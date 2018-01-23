FROM debian:jessie
MAINTAINER vannk <vansunny12@gmail.com>

# The Dotdeb repository for Php 7
RUN apt-get update && apt-get install -y wget git re2c apt-utils apt-transport-https \
    &&  echo 'deb http://packages.dotdeb.org jessie all' > /etc/apt/sources.list.d/dotdeb.list \
    && wget https://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg  && rm dotdeb.gpg\
    && apt-get update \
    && apt-get -y install apache2 \
    php7.0 \
    php7.0-dev \
    libapache2-mod-php7.0 \
    php7.0-common \
    php-pear \
    php7.0-curl \
    php7.0-gd \
    php7.0-imagick \
    php7.0-intl \
    php7.0-mcrypt \
    php7.0-pgsql \
    php7.0-opcache \
    php7.0-mysql \
    php7.0-mongodb \
    php7.0-bz2 \
    && apt-get clean

#Phalcon installation
WORKDIR /tmp
RUN git clone --depth=1 http://github.com/phalcon/cphalcon.git \
    && cd cphalcon/build \
    && ./install \
    && echo 'extension=phalcon.so' > /etc/php/7.0/mods-available/phalcon.ini \
    && echo 'extension=phalcon.so' > /etc/php/7.0/apache2/conf.d/50-phalcon.ini \
    && echo 'extension=phalcon.so' > /etc/php/7.0/cli/conf.d/50-phalcon.ini
RUN git clone http://github.com/phalcon/phalcon-devtools.git \
    && cd phalcon-devtools/ \
    && . /home/phalcon/phalcon-devtools/phalcon.sh \
    && ln -s /home/phalcon/phalcon-devtools/phalcon.php /usr/local/bin/phalcon \
    && chmod +x /usr/local/bin/phalcon

RUN /usr/sbin/a2dismod 'mpm_*' && /usr/sbin/a2enmod mpm_prefork
RUN /usr/sbin/a2enmod rewrite
ADD 000-phalcon.conf /etc/apache2/sites-available/
ADD 001-phalcon-ssl.conf /etc/apache2/sites-available/
RUN /usr/sbin/a2dissite '*' && /usr/sbin/a2ensite 000-phalcon 001-phalcon-ssl
RUN a2enmod expires
RUN a2enmod headers

RUN curl -o mod-pagespeed.deb https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-beta_current_amd64.deb && dpkg -i mod-pagespeed.deb && apt-get -f install
RUN /usr/sbin/php5enmod pagespeed

RUN rm -rf /var/www/phalcon/web
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/phalcon/web
RUN chown -R www-data:www-data /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/phalcon/web

WORKDIR /var/www/phalcon/web
RUN /bin/echo '<html><body><h1>It works!</h1></body></html>' > /var/www/phalcon/web/index.html
WORKDIR /var/www/phalcon

RUN ln -sf /dev/stdout /var/log/apache2/access.log
RUN ln -sf /proc/self/fd/1 /var/log/apache2/error.log

EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
