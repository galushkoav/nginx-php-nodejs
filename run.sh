#!/bin/bash
chown -R www-data /home/a/;
/etc/init.d/php7.0-fpm start;
/etc/init.d/nginx start;
/etc/init.d/syslog-ng start;
/bin/bash;