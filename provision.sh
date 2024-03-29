table_header(){
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                  CentOS LEMP Stack with Laravel                 │"
}
table_footer(){
    echo "├─────────────────────────────────────────────────────────────────┤"
    printf "%1s %6s %-56s %1s" "│" "[100%]" "  All done." "│"$'\n'
    echo "├─────────────────────────────────────────────────────────────────┤"
    echo "│             Laravel development server started...               │"
    echo "└─────────────────────────────────────────────────────────────────┘"
}
init(){
    # FIX ERROR: Invalid configuration value: failovermethod=priority, BCZ the failover method is no longer supported for EL8 since it has been removed from DNF
    sudo sed -i '/^failovermethod=/d' /etc/yum.repos.d/*.repo
    cd /etc/yum.repos.d/
    sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
    sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
    yum update -y
    # IN CASE OF 'GUEST ADDITIONS' PROBLEM, SSH INTO THE VM AND TYPE IN: (with Centos 8 may not help, then try Centos 7)
    # sudo yum install -y kernel-devel && sudo yum update -y kernel
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
    yum install -y yum-utils
    yum install -y nano
    # COLORFUL TERMINAL HOSTNAME & DIRECTORY: in /home/vagrant/.bashrc paste this: export PS1="\[$(tput bold)\]\[\033[48;5;36m\] \u @ \h \[$(tput sgr0)\]\[\033[48;5;24m\] \W \[$(tput bold)\]\[\033[38;5;0m\]\[\033[48;5;\]\$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')\[$(tput sgr0)\] \\$ "
  
}
install_nginx(){
    yum install -y nginx
}
adjust_firewall(){
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --list-all
    firewall-cmd --reload
}
install_php(){
    yum-config-manager --disable 'remi-php*'
    yum-config-manager --enable remi-php80
    yum install -y php php-{cli,fpm,mysqlnd,zip,devel,gd,mbstring,curl,xml,pear,bcmath,json}
    # yum install -y php php-fpm php-mysqlnd
    sudo cp /vagrant/php-fpm--www.conf /etc/php-fpm.d/www.conf
    cp /vagrant/php.ini /etc/php.ini
    cd /etc/nginx/
    mkdir sites-available sites-enabled
    cp /vagrant/dev.local.conf conf.d/dev.local.conf
    cp conf.d/dev.local.conf sites-available/dev.local.conf 
    ln -fs sites-available/dev.local.conf sites-enabled
}
install_mysql(){
    yum install -y mariadb mariadb-server
    systemctl enable mariadb
    systemctl start mariadb
    systemctl status mariadb
    yum install -y expect
}
secure_mysql(){
    if [ $(which mysql) = "" ]; then
        MYSQL_ROOT_PASSWORD=12345
        expect -c "set timeout 1
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
            # mysql -u root --password=$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS VAGRANT_DB; SHOW DATABASES;"
    fi
}
install_phpmyadmin(){
    yum install -y php-json php-mbstring
    wget https://files.phpmyadmin.net/phpMyAdmin/5.0.1/phpMyAdmin-5.0.1-all-languages.tar.gz
    tar -zxvf phpMyAdmin-5.0.1-all-languages.tar.gz
    mv phpMyAdmin-5.0.1-all-languages /usr/share/phpMyAdmin
    cp -pr /usr/share/phpMyAdmin/config.sample.inc.php /usr/share/phpMyAdmin/config.inc.php
    cp /vagrant/conf.d--phpmyadmin.conf conf.d/phpmyadmin.conf
    cp /vagrant/phpmyadmin--config.inc.php /usr/share/phpMyAdmin/config.inc.php
    mkdir /usr/share/phpMyAdmin/tmp
    chmod 777 /usr/share/phpMyAdmin/tmp
    chmod 777 /var/lib/php/session/
    chown -R nginx:nginx /usr/share/phpMyAdmin
    mysql < /usr/share/phpMyAdmin/sql/create_tables.sql -u root --password=$MYSQL_ROOT_PASSWORD
}
start_services(){
    systemctl start nginx
    systemctl start php-fpm
    systemctl start mysql
    systemctl enable nginx
    systemctl enable php-fpm
}
install_git(){
    yum install -y https://packages.endpoint.com/rhel/7/os/x86_64/endpoint-repo-1.7-1.x86_64.rpm
    yum install -y git
}
install_nodejs(){
    # Stable release:
    yum install -y gcc-c++ make 
    curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash - 
    yum install -y nodejs
}
install_composer(){
    yum install -y php-cli php-json php-zip wget unzip
    curl -sS https://getcomposer.org/installer |php
    mv composer.phar /usr/local/bin/composer
}
install_laravel(){
    yum install -y php-xml php-mbstring &> /dev/null
    # cannot make alias composer="php /usr/local/bin/composer" at this phase
    php /usr/local/bin/composer global require cviebrock/eloquent-sluggable laravel/installer &> /dev/null
    export PATH="$PATH:$HOME/.config/composer/vendor/bin"
    cd /etc/nginx/
    cp /vagrant/laravel.local.conf conf.d/laravel.local.conf
    cp /vagrant/laravel.local.conf sites-available/laravel.local.conf
    ln -s /etc/nginx/sites-available/laravel.local.conf /etc/nginx/sites-enabled/laravel.local.conf &> /dev/null #must be pull path
    mkdir /vagrant/msn-laravel &> /dev/null 
    cd /vagrant/msn-laravel
    print_inside "├─ Create Laravel project.."
    php /usr/local/bin/composer create-project laravel/laravel . &> /dev/null # because "laravel new /vagrant/msn-laravel" does not work
    print_inside "├─ Install Laravel vendor.."
    php /usr/local/bin/composer install --ignore-platform-reqs &> /dev/null
    print_inside "├─ $(php artisan --version)"
    print_inside "└─ Generate project key.."
    php artisan key:generate &> /dev/null
    systemctl restart nginx
    systemctl restart php-fpm
}
laravel_serve(){
    cd /vagrant/msn-laravel && php artisan serve &   # php -S localhost:8000 -t /vagrant/msn-laravel/public/&> /dev/null
}

total_steps=12
tot_length=30
current_step=1
percent=0
progress_messages=''
print_progress(){
    percent=$(((($current_step-1)*100)/$total_steps))
    echo "├─────────────────────────────────────────────────────────────────┤"
    printf "%1s %6s %9s %-45s %1s" "│" "["$percent"%]" "Step ${current_step}:" "$1" " │"$'\n'
    ((current_step++))
}
print_inside(){
    printf "%1s %-16s %-50s %1s" "│" " " "$1" "│"$'\n'
}

main(){
    table_header

    print_progress "Update package manager"
    init &> /dev/null

    print_progress "Install & configure nginx"
    install_nginx &> /dev/null

    print_progress "Adjust Firewall Rules"
    adjust_firewall &> /dev/null
 #---------------------------------------------------------------
    print_progress "Install & configure php"
    install_php &> /dev/null
    print_inside "└─ $(php --version | grep ^PHP | cut -c1-10)"

    print_progress "Install, secure & configure mysql"
    install_mysql &> /dev/null
    secure_mysql &> /dev/null 
    print_inside "└─ $(mysql --version | grep ^mysql | cut -c1-30)"

    print_progress "Install & configure phpmyadmin"
    install_phpmyadmin &> /dev/null
            
    print_progress "Starting & enabling services"
    start_services &> /dev/null
 #---------------------------------------------------------------
    print_progress "Install Git" 
    install_git &> /dev/null
    print_inside "└─ $(git --version | grep ^git | cut -c1-30)"

    print_progress "Install Nodejs" 
    install_nodejs &> /dev/null
    print_inside "└─ Nodejs $(node --version | cut -c1-30)"

    print_progress "Install Composer"
    install_composer &> /dev/null

    print_progress "Install & configure Laravel"
    install_laravel
    laravel_serve

    table_footer
} 
###
main
