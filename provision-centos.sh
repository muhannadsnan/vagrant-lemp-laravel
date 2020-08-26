init(){
    yum update
    yum install -y nano
}
install_nginx(){
    yum install -y nginx
    cd /etc/nginx/
    mkdir sites-available sites-enabled
    cp /vagrant/dev.local.conf sites-available/dev.local.conf
    cp sites-available/dev.local.conf conf.d/dev.local.conf
    ln -fs sites-available/dev.local.conf sites-enabled
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
    cp /vagrant/conf.d--phpmyadmin.conf /etc/nginx/conf.d/phpmyadmin.conf
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



progress_bar() {
    CODE_SAVE_CURSOR="\033[s"; CODE_RESTORE_CURSOR="\033[u"; CODE_CURSOR_IN_SCROLL_AREA="\033[1A"; COLOR_FG="\e[30m"; COLOR_BG="\e[42m"; COLOR_BG_BLOCKED="\e[43m"; RESTORE_FG="\e[39m"; RESTORE_BG="\e[49m"; PROGRESS_BLOCKED="false"
    percentage=$1
    lines=$(tput lines)
    let lines=$lines
    echo -en "$CODE_SAVE_CURSOR" # Save cursor
    echo -en "\033[${lines};0f" # Move cursor position to last row
    tput el # Clear progress bar
    PROGRESS_BLOCKED="true" # Draw progress bar
    print_bar_text $percentage
    echo -en "$CODE_RESTORE_CURSOR" # Restore cursor position
}
print_bar_text() {
    local percentage=$1
    local cols=$(tput cols)
    let bar_size=$cols-17
    local color="${COLOR_FG}${COLOR_BG}"
    if [ "$PROGRESS_BLOCKED" = "true" ]; then
        color="${COLOR_FG}${COLOR_BG_BLOCKED}"
    fi
    # Prepare progress bar
    let complete_size=($bar_size*$percentage)/100
    let remainder_size=$bar_size-$complete_size
    progress_bar=$(echo -ne "["; 
    echo -en "${color}"; 
    printf_new "#" $complete_size; 
    echo -en "${RESTORE_FG}${RESTORE_BG}"; 
    printf_new "." $remainder_size; echo -ne "]");
    # Print progress bar
    echo -ne " Progress ${percentage}% ${progress_bar}\n\n"
}
printf_new() {
    str=$1
    num=$2
    v=$(printf "%-${num}s" "$str")
    echo -ne "${v// /$str}"
}
destroy_scroll_area() {
    lines=$(tput lines)
    echo -en "$CODE_SAVE_CURSOR"
    echo -en "\033[0;${lines}r"
    echo -en "$CODE_RESTORE_CURSOR"
    echo -en "$CODE_CURSOR_IN_SCROLL_AREA"
    clear_progress_bar
    if [ "$TRAP_SET" = "true" ]; then
        trap - INT
    fi
}
clear_progress_bar() {
    lines=$(tput lines)
    let lines=$lines
    echo -en "$CODE_SAVE_CURSOR"
    echo -en "\033[${lines};0f"
    tput el
    echo -en "$CODE_RESTORE_CURSOR"
}


total_steps=7
current_step=1
percent=0
progress(){
    tot_length=30
    percent=$((($current_step*100)/$total_steps))
    sleep 0.2
    ((current_step++))
    echo -n $1;
    progress_bar $percent;
}

main(){
    echo "Welcome to My Vagrant"
    progress "Step ${current_step}:   Update for package manager"
    # init &> /dev/null

    progress "Step ${current_step}:   Install & configure nginx"
    # install_nginx &> /dev/null

    progress "Step ${current_step}:   Adjust Firewall Rules"
    adjust_firewall &> /dev/null

    progress "Step ${current_step}:   Install & configure php"
    # install_php &> /dev/null

    progress "Step ${current_step}:   Install & secure & configure mysql"
    # install_mysql &> /dev/null

    # secure_mysql &> /dev/null 
    progress "Step ${current_step}:   Install & configure phpmyadmin"
    # install_phpmyadmin &> /dev/null
    
    progress "Step ${current_step}:   Starting & enabling services"
    start_services &> /dev/null


    echo "Done successfully. The LEMP stack was installed for you!"
    destroy_scroll_area
} 
###
main