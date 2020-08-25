echo "----------------- Welcome to my Vagrant! -----------------"
yum update
yum install -y nano

echo "----------------- Step 1: Install & configure nginx -----------------"
yum install -y nginx
cd /etc/nginx/
mkdir sites-available sites-enabled
cp /vagrant/dev.local.conf sites-available/dev.local.conf
cp sites-available/dev.local.conf conf.d/dev.local.conf
ln -fs sites-available/dev.local.conf sites-enabled

echo "----------------- Step 2: Adjust Firewall Rules -----------------"
#adjust the firewall settings in order to allow external connections on your Nginx web server, which runs on port 80 by default.
#setenforce permissive
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --list-all
firewall-cmd --reload

echo "----------------- Step 3: Install & configure php -----------------"
yum install -y php php-fpm php-mysqlnd
sudo cp /vagrant/php-fpm--www.conf /etc/php-fpm.d/www.conf
cp /vagrant/php.ini /etc/php.ini

echo "----------------- Step 4: Install & secure & configure mysql -----------------"
yum install -y mariadb mariadb-server
systemctl enable mariadb
systemctl start mariadb
systemctl status mariadb
yum install -y expect
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
expect eof"

mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES; CREATE DATABASE VAGRANT_DB; EXIT;"
yum remove -y expect

echo "----------------- Install & configure phpmyadmin -----------------"
yum install -y php-json php-mbstring
wget https://files.phpmyadmin.net/phpMyAdmin/5.0.1/phpMyAdmin-5.0.1-all-languages.tar.gz
tar -zxvf phpMyAdmin-5.0.1-all-languages.tar.gz
mv phpMyAdmin-5.0.1-all-languages /usr/share/phpMyAdmin
cp -pr /usr/share/phpMyAdmin/config.sample.inc.php /usr/share/phpMyAdmin/config.inc.php
cp /vagrant/conf.d--phpmyadmin.conf /etc/nginx/conf.d/phpmyadmin.conf
cp /vagrant/phpmyadmin--config.inc.php /usr/share/phpMyAdmin/config.inc.php
mkdir /usr/share/phpMyAdmin/tmp
chmod 777 /usr/share/phpMyAdmin/tmp
chmod 777 /var/lib/php/session/
chown -R nginx:nginx /usr/share/phpMyAdmin
mysql < /usr/share/phpMyAdmin/sql/create_tables.sql -u root --password=$MYSQL_ROOT_PASSWORD


echo "----------------- Starting & enabling services NGINX & PHP-FPM -----------------";
systemctl start nginx
systemctl start php-fpm
systemctl start mysql
systemctl enable nginx
systemctl enable php-fpm

echo "----------------- Done! -----------------"

# https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-8