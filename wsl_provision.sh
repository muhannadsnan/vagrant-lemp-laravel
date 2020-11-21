DIR=''
CLR0='\033[0m' # No Color
CLR1='\033[1;32m'
CLR2='\033[0;33m'
CLR3='\033[1;37m'
# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37
table_header(){
    printf "\n\n\n"
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo -e "│            ${CLR1} CentOS LEMP Stack with Laravel for WSL ${CLR0}             │"
}
table_footer(){
    echo "├─────────────────────────────────────────────────────────────────┤"
    printf "$CLR1%1s %6s %-56s %1s$CLR0" "│" "[100%]" "All done." "│"$'\n'
    echo "├─────────────────────────────────────────────────────────────────┤"
    echo -e "│             Laravel development server started...               │"
    echo "└─────────────────────────────────────────────────────────────────┘"
}
init(){
    DIR="$( cd "$( dirname "$0" )" && pwd )" # current folder
    yum update -y
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
    yum install -y nano
    # fix systemctl in wsl
    mv /usr/bin/systemctl /usr/bin/systemctl.old
    curl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py > /usr/bin/systemctl
    chmod +x /usr/bin/systemctl
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
    yum install -y yum-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm
    yum-config-manager --enable remi-php74
    yum update -y
    yum install -y php php-fpm php-common php-opcache php-mcrypt php-cli php-gd php-curl php-mysql
    cp $DIR/php-fpm--www.conf /etc/php-fpm.d/www.conf
    cp $DIR/php.ini /etc/php.ini
    cd /etc/nginx/
    mkdir sites-available sites-enabled
    cp $DIR/dev.local.conf conf.d/dev.local.conf
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
    cp $DIR/conf.d--phpmyadmin.conf conf.d/phpmyadmin.conf
    cp $DIR/phpmyadmin--config.inc.php /usr/share/phpMyAdmin/config.inc.php
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
    yum install -y git
}
install_nodejs(){
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
    cp $DIR/laravel.local.conf conf.d/laravel.local.conf
    cp $DIR/laravel.local.conf sites-available/laravel.local.conf
    ln -s /etc/nginx/sites-available/laravel.local.conf /etc/nginx/sites-enabled/laravel.local.conf &> /dev/null #must be pull path
    mkdir $DIR/msn-laravel &> /dev/null 
    cd $DIR/msn-laravel
    print_inside "├─ Create Laravel project.."
    php /usr/local/bin/composer create-project laravel/laravel . &> /dev/null # because "laravel new $DIR/msn-laravel" does not work
    print_inside "├─ Install Laravel vendor.."
    php /usr/local/bin/composer install --ignore-platform-reqs 2>&1 &> /dev/null
    print_inside "├─ $(php artisan --version)"
    print_inside "└─ Generate project key.."
    php artisan key:generate &> /dev/null
    systemctl restart nginx
    systemctl restart php-fpm
}
laravel_serve(){
    cd $DIR/msn-laravel && php artisan serve &   # php -S localhost:8000 -t $DIR/msn-laravel/public/&> /dev/null
}

total_steps=12
tot_length=30
current_step=1
percent=0
progress_messages=''
print_progress(){
    percent=$(((($current_step-1)*100)/$total_steps))
    echo "├─────────────────────────────────────────────────────────────────┤"
    printf "%1s $CLR2%6s$CLR0 %9s %-45s %1s" "│" "["$percent"%]" "Step ${current_step}:" "$1" " │"$'\n'
    ((current_step++))
}
print_inside(){
    printf "%1s %-16s $CLR3%-50s$CLR0 %1s" "│" " " "$1" "│"$'\n'
}

main(){
    table_header

    print_progress "Update package manager & repositories"
    init &> /dev/null

    print_progress "Install & configure nginx"
    install_nginx &> /dev/null
    print_inside "└─ $(nginx -v 2>&1 | cut -c16-60)"

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