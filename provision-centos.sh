echo "----------------- Welcome to my Vagrant! -----------------"
echo "----------------- Step 1: install nginx -----------------"
yum install -y nginx
systemctl start nginx
systemctl enable nginx
#ln -fs /vagrant /var/www/local.dev

echo "----------------- Step 2: configure nginx -----------------"
cd /etc/nginx/
mkdir sites-available sites-enabled
cp /vagrant/local.dev.conf sites-available/local.dev.conf
cp sites-available/local.dev.conf conf.d/local.dev.conf
ln -fs sites-available/local.dev.conf sites-enabled
cp /vagrant/nginx.conf nginx.conf
systemctl restart nginx
nginx -t

echo "----------------- Step 3: Adjust Firewall Rules -----------------"
#adjust the firewall settings in order to allow external connections on your Nginx web server, which runs on port 80 by default.
#setenforce permissive
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --list-all
firewall-cmd --reload

yum install nano

echo "----------------- Done! -----------------"