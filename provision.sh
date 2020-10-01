init(){
    yum update
    yum install -y nano
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
    yum install -y php php-fpm php-mysqlnd
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
    echo "│                      ├─ Create Laravel project..            │"
    php /usr/local/bin/composer create-project laravel/laravel /vagrant/msn-laravel/. &> /dev/null # because "laravel new /vagrant/msn-laravel" does not work
    cd /vagrant/msn-laravel
    echo "│                      ├─ Install Laravel vendor..            │"
    php /usr/local/bin/composer install --ignore-platform-reqs &> /dev/null
    echo "│                      ├─ Generate project key..              │"
    php artisan key:generate &> /dev/null
    systemctl restart nginx
    systemctl restart php-fpm
}

total_steps=9
tot_length=30
current_step=1
percent=0
progress_messages=''
print_progress(){
    percent=$(((($current_step-1)*100)/$total_steps))
    echo "├─────────────────────────────────────────────────────────────┤"
    echo -e "│  ["$percent"%]$1│"
    progress_messages+="$msg"
    ((current_step++))
}

main(){
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│               CentOS LEMP Stack with Laravel                │"
    print_progress "    Step ${current_step}:   Update package manager                   "
    # init &> /dev/null

    print_progress "   Step ${current_step}:   Install & configure nginx                "
    # install_nginx &> /dev/null

    print_progress "   Step ${current_step}:   Adjust Firewall Rules                    "
    # adjust_firewall &> /dev/null

    print_progress "   Step ${current_step}:   Install & configure php                  "
    # install_php &> /dev/null

    print_progress "   Step ${current_step}:   Install, secure & configure mysql        "
    # install_mysql &> /dev/null
    # secure_mysql &> /dev/null 

    print_progress "   Step ${current_step}:   Install & configure phpmyadmin           "
    # install_phpmyadmin &> /dev/null
            
    print_progress "   Step ${current_step}:   Starting & enabling services             "
    # start_services &> /dev/null

    print_progress "   Step ${current_step}:   Install Composer                         "
    # install_composer &> /dev/null

    print_progress "   Step ${current_step}:   Install & configure Laravel              "
    # install_laravel

    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│  [100%]  All done.                                          │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│          Laravel development server started...              │"
    echo "└─────────────────────────────────────────────────────────────┘"
    cd /vagrant/msn-laravel && php artisan serve & # php -S localhost:8000 -t /vagrant/msn-laravel/public/&> /dev/null
} 
###
main