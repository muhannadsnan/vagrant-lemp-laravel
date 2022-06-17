- CentOS
- Nginx
- PHP
- Mysql
- PhpMyAdmin
- Laravel
- Git
- Composer
- Nodejs
 
In hosts file use these domains:

10.0.0.10 dev.local

10.0.0.10 phpmyadmin.local

10.0.0.10 laravel.local

=================================================
IMPORTANT:
After running vagrant up, you might face a problem, which is that the linux kernel need to be updated in order to have the vbox guest additions working, so you ssh into the vagrant box and run this:

sudo yum -y install kernel-devel && sudo yum update -y kernel

Then exit and vagrant up again.
