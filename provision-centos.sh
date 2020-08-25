echo "----------------- Welcome to my Vagrant! -----------------"
yum update &> /dev/null
yum install -y nano &> /dev/null

echo "----------------- Step 1: Install & configure nginx -----------------"
yum install -y nginx &> /dev/null
cd /etc/nginx/
mkdir sites-available sites-enabled
cp /vagrant/dev.local.conf sites-available/dev.local.conf
cp sites-available/dev.local.conf conf.d/dev.local.conf
ln -fs sites-available/dev.local.conf sites-enabled &> /dev/null

echo "----------------- Step 2: Adjust Firewall Rules -----------------"
#adjust the firewall settings in order to allow external connections on your Nginx web server, which runs on port 80 by default.
#setenforce permissive
firewall-cmd --permanent --add-service=http &> /dev/null
firewall-cmd --permanent --list-all &> /dev/null
firewall-cmd --reload &> /dev/null

echo "----------------- Step 3: Install & configure php -----------------"
yum install -y php php-fpm php-mysqlnd &> /dev/null
sudo cp /vagrant/php-fpm--www.conf /etc/php-fpm.d/www.conf
cp /vagrant/php.ini /etc/php.ini

echo "----------------- Step 4: Install & secure & configure mysql -----------------"
yum install -y mariadb mariadb-server &> /dev/null
systemctl enable mariadb &> /dev/null
systemctl start mariadb &> /dev/null
systemctl status mariadb &> /dev/null
yum install -y expect &> /dev/null
MYSQL_ROOT_PASSWORD=12345
expect -c "set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root*\"
send \"$MYSQL\r\"
expect \"Set root password?\"
send \"y\r\"
expect \"New password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof" &> /dev/null

mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES; CREATE DATABASE VAGRANT_DB; EXIT;" &> /dev/null
yum remove -y expect &> /dev/null

echo "----------------- Install & configure phpmyadmin -----------------"
yum install -y php-json php-mbstring &> /dev/null
wget https://files.phpmyadmin.net/phpMyAdmin/5.0.1/phpMyAdmin-5.0.1-all-languages.tar.gz &> /dev/null
tar -zxvf phpMyAdmin-5.0.1-all-languages.tar.gz &> /dev/null
mv phpMyAdmin-5.0.1-all-languages /usr/share/phpMyAdmin
cp -pr /usr/share/phpMyAdmin/config.sample.inc.php /usr/share/phpMyAdmin/config.inc.php &> /dev/null
cp /vagrant/conf.d--phpmyadmin.conf /etc/nginx/conf.d/phpmyadmin.conf
cp /vagrant/phpmyadmin--config.inc.php /usr/share/phpMyAdmin/config.inc.php
mkdir /usr/share/phpMyAdmin/tmp
chmod 777 /usr/share/phpMyAdmin/tmp &> /dev/null
chmod 777 /var/lib/php/session/ &> /dev/null
chown -R nginx:nginx /usr/share/phpMyAdmin &> /dev/null
mysql < /usr/share/phpMyAdmin/sql/create_tables.sql -u root --password=$MYSQL_ROOT_PASSWORD &> /dev/null


echo "----------------- Starting & enabling services NGINX & PHP-FPM -----------------";
systemctl start nginx &> /dev/null
systemctl start php-fpm &> /dev/null
systemctl start mysql &> /dev/null
systemctl enable nginx &> /dev/null
systemctl enable php-fpm &> /dev/null

echo "----------------- Done! -----------------"

# https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-8