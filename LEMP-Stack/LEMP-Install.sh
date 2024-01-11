#!/bin/bash

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires administrative privileges. Please run with sudo:"
    echo "sudo $0"
    exit 1
fi

echo -e "
>>========================<<
||                        ||
||                        ||
||    ██████╗ ██╗  ██╗    ||
||    ██╔══██╗██║ ██╔╝    ||
||    ██║  ██║█████╔╝     ||
||    ██║  ██║██╔═██╗     ||
||    ██████╔╝██║  ██╗    ||
||    ╚═════╝ ╚═╝  ╚═╝    ||
||                        ||
||                        ||
>>========================<<                                                                                                                        
"

# Welcome Message
echo -e "
>>==============================================================<<
|              LEMP Stack Installation Script                    |
|----------------------------------------------------------------|
| This script automates the installation of the LEMP stack       |
| A software stack is a set of tools bundled together.           |
| LEMP stands for Linux, Nginx (Engine-X), MariaDB/MySQL, & PHP  |
| All open source and free to use.                               |
>>==============================================================<<
"

# Prompt for user confirmation
read -p "Do you want to continue? (Y/n): " choice

if [ "$choice" != "Y" ]; then
    echo "Bye!"
    exit 0
fi

# Function to display step status
show_status() {
    echo -e "\e[93m[  Pending  ]\e[0m - $1"
}

# Function to display completed step
show_completed() {
    echo -e "\e[92m[ Completed ]\e[0m - $1"
}

# Function to display error and exit
show_error() {
    echo -e "\e[91m[   Error   ]\e[0m - $1"
    echo "$2"
    read -p "Press Enter to continue..."
    cleanup_and_exit
}

# Function to cleanup and exit
cleanup_and_exit() {
    cd ..
    rm -rf "$(basename "$(pwd)")"
    exit 1
}

# Step 1: Update and Upgrade System Packages
# This step updates the package information, upgrades installed packages to the latest version, removes unnecessary packages, and cleans the package cache to free up disk space.
show_status "Update and Upgrade System Packages"
sudo apt update -y && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean -y && sudo apt autoclean -y
if [ $? -eq 0 ]; then
    show_completed "Update and Upgrade System Packages"
else
    show_error "Update and Upgrade System Packages" "Failed to update and upgrade system packages."
fi

# Step 2: Install Nginx Web Server
# This step checks if Nginx is installed. If not, it installs Nginx, enables it to start at boot, starts the Nginx service, and checks the status of the service.
show_status "Install Nginx Web Server"
if ! command -v nginx &> /dev/null; then
    sudo apt install nginx
    if [ $? -eq 0 ]; then
        sudo systemctl enable nginx
        sudo systemctl start nginx
        sudo systemctl status nginx
        show_completed "Install Nginx Web Server"
    else
        show_error "Install Nginx Web Server" "Failed to install Nginx."
    fi
else
    show_completed "Nginx is already installed"
fi

# Step 3: Configure Firewall for Nginx (if applicable)
# This part opens TCP port 80 in the Firewall, either using iptables or UFW, to allow HTTP traffic.
# Open TCP port 80 if using iptables Firewall
show_status "Configure Firewall for Nginx"
if command -v iptables &> /dev/null; then
    sudo iptables -C INPUT -p tcp --dport 80 -j ACCEPT || sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
fi
show_completed "Configure Firewall for Nginx"

# Open TCP port 80 if using UFW Firewall
if command -v ufw &> /dev/null; then
    sudo ufw allow http
fi

# Step 4: Set Nginx Web Directory Ownership
# This step sets the ownership of the Nginx web directory to the www-data user and group.
show_status "Set Nginx Web Directory Ownership"
sudo chown www-data:www-data /usr/share/nginx/html -R
if [ $? -eq 0 ]; then
    show_completed "Set Nginx Web Directory Ownership"
else
    show_error "Set Nginx Web Directory Ownership" "Failed to set Nginx web directory ownership."
fi

# Step 5: Install MariaDB Database Server
# This part installs MariaDB if it's not already installed. It then automates responses to mysql_secure_installation prompts using the expect command.
show_status "Install MariaDB Database Server"
if ! command -v mariadb &> /dev/null; then
    sudo apt install mariadb-server mariadb-client
    if [ $? -eq 0 ]; then
        sudo systemctl start mariadb
        sudo systemctl enable mariadb
        show_completed "Install MariaDB Database Server"
    else
        show_error "Install MariaDB Database Server" "Failed to install MariaDB."
    fi

    # Automate responses to mysql_secure_installation prompts
    SECURE_MYSQL_INSTALLATION=$(expect -c "
        set timeout 3
        spawn sudo mysql_secure_installation
        expect \"Enter current password for root (enter for none):\"
        send \"\r\"
        expect \"Set root password?\"
        send \"n\r\"
        expect \"Remove anonymous users?\"
        send \"\r\"
        expect \"Disallow root login remotely?\"
        send \"\r\"
        expect \"Remove test database and access to it?\"
        send \"\r\"
        expect \"Reload privilege tables now?\"
        send \"\r\"
        expect eof
    ")

    if [ $? -ne 0 ]; then
        show_error "Secure MySQL Installation" "Failed to secure MySQL installation." 
    fi
else
    show_completed "MariaDB is already installed"
fi

# Step 6: Install PHP 8.1 and Configure PHP
# This step installs PHP 8.1 and some common PHP extensions. It starts the PHP 8.1 FPM service, enables it to start at boot, and checks the status of the service.
show_status "Install PHP 8.1 and Configure PHP"
if ! command -v php8.1 &> /dev/null; then
    sudo apt install php8.1 php8.1-fpm php8.1-mysql php-common php8.1-cli php8.1-common php8.1-opcache php8.1-readline php8.1-mbstring php8.1-xml php8.1-gd php8.1-curl
    if [ $? -eq 0 ]; then
        sudo systemctl start php8.1-fpm
        sudo systemctl enable php8.1-fpm
        sudo systemctl status php8.1-fpm
        show_completed "Install PHP 8.1 and Configure PHP"
    else
        show_error "Install PHP 8.1 and Configure PHP" "Failed to install PHP 8.1."
    fi
else
    show_completed "PHP 8.1 is already installed"
fi

# Step 7: Create Nginx Server Block Configuration
# This part creates an Nginx server block configuration file if it doesn't exist. The configuration defines how Nginx should handle PHP files and other static files.
show_status "Create Nginx Server Block Configuration"
NGINX_SERVER_BLOCK="/etc/nginx/conf.d/default.conf"
if [ ! -f "$NGINX_SERVER_BLOCK" ]; then
    sudo tee "$NGINX_SERVER_BLOCK" > /dev/null <<EOF
# Nginx server block configuration
server {
  listen 80;
  listen [::]:80;
  server_name _;
  root /usr/share/nginx/html/;
  index index.php index.html index.htm index.nginx-debian.html;

  location / {
    try_files \$uri \$uri/ /index.php;
  }

  location ~ \.php$ {
    fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include fastcgi_params;
    include snippets/fastcgi-php.conf;
  }

  # A long browser cache lifetime can speed up repeat visits to your page
  location ~* \.(jpg|jpeg|gif|png|webp|svg|woff|woff2|ttf|css|js|ico|xml)$ {
       access_log        off;
       log_not_found     off;
       expires           360d;
  }

  # disable access to hidden files
  location ~ /\.ht {
      access_log off;
      log_not_found off;
      deny all;
  }
}
EOF
    sudo nginx -t
    if [ $? -eq 0 ]; then
        sudo systemctl reload nginx
        show_completed "Create Nginx Server Block Configuration"
    else
        show_error "Create Nginx Server Block Configuration" "Failed to create Nginx server block configuration."
    fi
else
    show_completed "Nginx Server Block Configuration already exists"
fi

# Step 8: Improve PHP Performance
# This step creates a custom PHP configuration file to improve PHP performance by adjusting memory limits and OPcache settings.
show_status "Improve PHP Performance"
PHP_CUSTOM_CONFIG="/etc/php/8.1/fpm/conf.d/60-custom.ini"
if [ ! -f "$PHP_CUSTOM_CONFIG" ]; then
    sudo tee "$PHP_CUSTOM_CONFIG" > /dev/null <<EOF
; Custom PHP configuration
; Maximum amount of memory a script may consume. Default is 128M
memory_limit = 512M

; Maximum allowed size for uploaded files. Default is 2M.
upload_max_filesize = 20M

; Maximum size of POST data that PHP will accept. Default is 2M.
post_max_size = 20M

; The OPcache shared memory storage size. Default is 128
opcache.memory_consumption=256

; The amount of memory for interned strings in Mbytes. Default is 8.
opcache.interned_strings_buffer=32
EOF
    sudo systemctl reload php8.1-fpm
    show_completed "Improve PHP Performance"
else
    show_completed "PHP Performance already improved"
fi


# Step 9: Configure Nginx Automatic Restart
# This part configures Nginx to automatically restart with a delay of 5 seconds in case of failure.
show_status "Configure Nginx Automatic Restart"
NGINX_RESTART_CONF="/etc/systemd/system/nginx.service.d/restart.conf"
if [ ! -f "$NGINX_RESTART_CONF" ]; then
    sudo mkdir -p "$(dirname $NGINX_RESTART_CONF)"
    sudo tee "$NGINX_RESTART_CONF" > /dev/null <<EOF
# Nginx automatic restart configuration
[Service]
Restart=always
RestartSec=5s
EOF
    sudo systemctl daemon-reload
    if [ $? -eq 0 ]; then
        show_completed "Configure Nginx Automatic Restart"
    else
        show_error "Configure Nginx Automatic Restart" "Failed to configure Nginx automatic restart."
    fi
else
    show_completed "Nginx Automatic Restart Configuration already exists"
fi

# Step 10: Configure MariaDB Automatic Restart
# This part configures MariaDB to automatically restart with a delay of 5 seconds in case of failure.
show_status "Configure MariaDB Automatic Restart"
MARIADB_RESTART_CONF="/etc/systemd/system/mariadb.service.d/restart.conf"
if [ ! -f "$MARIADB_RESTART_CONF" ]; then
    sudo mkdir -p "$(dirname $MARIADB_RESTART_CONF)"
    sudo tee "$MARIADB_RESTART_CONF" > /dev/null <<EOF
# MariaDB automatic restart configuration
[Service]
Restart=always
RestartSec=5s
EOF
    sudo systemctl daemon-reload
    if [ $? -eq 0 ]; then
        show_completed "Configure MariaDB Automatic Restart"
    else
        show_error "Configure MariaDB Automatic Restart" "Failed to configure MariaDB automatic restart."
    fi
else
    show_completed "MariaDB Automatic Restart Configuration already exists"
fi

# Final Message
echo "Thank you!"

# Cleanup and exit
cd ..
rm -rf "$(basename "$(pwd)")"
