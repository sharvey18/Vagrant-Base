#!/bin/bash

if [ ! -f ~/.vagrant-provisioned ]
then
    touch ~/.vagrant-provisioned

    LOG_FILE=/vagrant/vagrant-files/logs/vagrant-provision.log
    LOCAL_PROVISION_SCRIPT=/vagrant/vagrant-files/provision-local.sh

    export DEBIAN_FRONTEND=noninteractive

    echo "127.0.0.1 vagrant.localhost" >> /etc/hosts

    echo "Updating Debian packages..."

    # update package lists
    apt-get -qq -y update &>> $LOG_FILE
    # upgrade all packages
    apt-get -qq -y upgrade &>> $LOG_FILE

    echo "Installing services..."

    # install default packages
    apt-get -qq -y install vim screen &>> $LOG_FILE
    apt-get -qq -y install apache2-mpm-worker libapache2-mod-fastcgi php5-fpm php5-cli php5-mysql php5-imagick php5-mcrypt php5-gd php5-curl php5-xdebug php5-sqlite &>> $LOG_FILE
    apt-get -qq -y install mysql-server &>> $LOG_FILE

    # install postfix for local mail relay
    debconf-set-selections <<< "postfix postfix/mailname string localhost.localdomain"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    apt-get install -qq -y postfix &>> $LOG_FILE

    echo "Configuring services..."

    # enable required apache packages
    a2enmod actions alias rewrite ssl &>> $LOG_FILE

    # install custom MySQL init script that includes backup on service shutdown
    cp /vagrant/vagrant-files/init.d/mysql /etc/init.d/
    # install the vagrant apache vhost file
    cp /vagrant/vagrant-files/conf/apache2/vagrant /etc/apache2/sites-available/
    # install the vagrant php-fpm pool config
    cp /vagrant/vagrant-files/conf/php5-fpm/vagrant.conf /etc/php5/fpm/pool.d/
    # install xdebug config
    cp /vagrant/vagrant-files/conf/php5-fpm/20-xdebug.ini /etc/php5/conf.d/

    # set up automated hourly snapshots of database
    crontab -u root -l > /tmp/cron-root &>> $LOG_FILE
    echo "0 * * * * sh /vagrant/vagrant-files/dump-databases.sh auto" >> /tmp/cron-root
    crontab -u root /tmp/cron-root
    rm /tmp/cron-root

    # import all database files in the "vagrant-files/databases/" folder
    # this will create a database for each ".sql" file in that directory with the same name as the file
    sh /vagrant/vagrant-files/import-databases.sh

    echo "Finalizing configuration..."

    # generate self-signed SSL certificate for apache
    mkdir /etc/apache2/certs
    cd /etc/apache2/certs
    /vagrant/vagrant-files/gen-cert.sh vagrant.localhost &>> $LOG_FILE

    # enable the vagrant.localhost vhost and disable the default vhost
    a2ensite vagrant &>> $LOG_FILE
    a2dissite default &>> $LOG_FILE

    # restart services to apply new configurations
    service apache2 restart &>> $LOG_FILE
    service php5-fpm restart &>> $LOG_FILE

    if [ -f $LOCAL_PROVISION_SCRIPT ]
    then
        echo "Running local provision script: $LOCAL_PROVISION_SCRIPT"
        /bin/bash $LOCAL_PROVISION_SCRIPT
    fi
fi

echo ""
echo "-------------------------------------"
echo "Add the following to your hosts file:"
echo "127.0.0.1 vagrant.localhost"
echo "You can then access the server at the"
echo "hostname 'vagrant.localhost' on the"
echo "ports specified in the config file"
echo "-------------------------------------"
echo ""
