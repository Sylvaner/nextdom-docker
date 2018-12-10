#!/bin/bash
echo 'Start init'

#Functions
makeZip(){
    echo makeZip $1
    [[ -z $1 ]] && echo no zipfile name given && exit -1
    for item in "backup/ core/ data/ desktop/ install/ mobile/ public/ scripts/ src/ tests/ \
    translations/ vendor/ views/ index.php package.json composer.json"
        do
            TOTAR+="${item} "
        done
    echo ${TOTAR}
    tar --warning=no-file-changed -zcf ${1} -C /var/www/html ${TOTAR}
    exitcode=$?
}

define_nextom_mysql_credentials(){
    confFile=/var/www/html/core/config/common.config.php
    sample=/var/www/html/core/config/common.config.sample.php
    [[ ! -e  ${sample} ]] && echo "${sample} is missing" && exit
    [[ -e  ${confFile} ]] && rm -f ${confFile}

    cp  ${sample} ${confFile}
    sed -i "s/#PASSWORD#/${MYSQL_PASSWORD}/g" ${confFile}
    sed -i "s/#DBNAME#/${MYSQL_DATABASE}/g" ${confFile}
    sed -i "s/#USERNAME#/${MYSQL_USER}/g" ${confFile}
    sed -i "s/#PORT#/${MYSQL_PORT}/g" ${confFile}
    sed -i "s/#HOST#/${MYSQL_HOST}/g" ${confFile}
}

# Main
set -x

if ! [ -f /.dockerinit ]; then
	touch /.dockerinit
	chmod 755 /.dockerinit
fi


if [ ! -z ${MODE_HOST} ] && [ ${MODE_HOST} -eq 1 ]; then
	echo 'Update /etc/hosts for host mode'
	echo "127.0.0.1 localhost nextdom" > /etc/hosts
fi

if [ -f "/var/www/html/_nextdom_is_installed" ]; then
	echo 'NextDom is already install'
else
	echo 'Start nextdom customization'
	define_nextom_mysql_credentials
	php /var/www/html/install/install.php
	touch /var/www/html/_nextdom_is_installed
	cd /root/export/;
	makeZip nextdom-${VERSION}.tar.gz
fi

echo 'All init complete'
mkdir -p /var/log/supervisor/ /var/log/apache2/ /var/log/nextdom/ && touch /var/log/nextdom/plugin
chown -R www-data:www-data /var/www/html /var/log/nextdom/
chmod 777 /dev/tty*
chmod 777 -R /tmp
chmod 755 -R /var/www/html /var/log/nextdom/


echo 'Start apache2'
systemctl restart apache2
service apache2 restart

#[[ $(ps -C cron | wc -l) -lt 2 ]] && /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf