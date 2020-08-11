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

echo "----------------- Starting & enabling services NGINX & PHP-FPM -----------------";
systemctl start nginx
systemctl start php-fpm
systemctl enable nginx
systemctl enable php-fpm

echo "----------------- Done! -----------------"

# https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-8