
# LEMP Stack Installation Script

Welcome to the LEMP (Linux, Nginx, MariaDB, PHP) stack installation guide!

🚀 This comprehensive script automates the process of setting up a powerful web development environment on your Debian-based system.

You can follow the steps bellow or you can run my script for automatic installation as described bellow.

## Prerequisites

Ensure you have **sudo** privileges to execute the script successfully. Let's dive into the installation steps!

## Step 1: Update and Upgrade System Packages

This step ensures that your system is up-to-date by updating package information, upgrading installed packages, removing unnecessary packages, and cleaning the package cache.

```
sudo apt update -y && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt clean -y && sudo apt autoclean -y
```

## Step 2: Install Nginx Web Server

Nginx is a high-performance web server, widely known for its efficiency.

Install Nginx

```
sudo apt install nginx
```

Enable Nginx to start at boot and initiate it:

```
sudo systemctl enable nginx
```

```
sudo systemctl start nginx
```

Verify its status:

```
sudo systemctl status nginx
```

## Step 3: Configure Firewall for Nginx (if applicable)

If applicable, open TCP port 80 in the firewall to allow HTTP traffic.

For iptables:

```
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
```

For UFW:

```
sudo ufw allow http
```

## Step 4: Set Nginx Web Directory Ownership

Set the ownership of the Nginx web directory to the www-data user and group.

```
sudo chown www-data:www-data /usr/share/nginx/html -R
```

## Step 5: Install MariaDB Database Server

Install MariaDB

```
sudo apt install mariadb-server mariadb-client
```

After it’s installed, MariaDB server should be automatically started. Use **systemctl** to check its status.

```
systemctl status mariadb
```

If it’s not running, start it with this command:

```
sudo systemctl start mariadb
```

To enable it to automatically start at boot time, run

```
sudo systemctl enable mariadb
```

Now run the post-installation security script.

```
sudo mysql_secure_installation
```

-   When it asks you to enter MariaDB root password, press Enter key as the root password isn’t set yet.
    
-   Don’t switch to unix_socket authentication because MariaDB is already using unix_socket authentication.
    
-   Don’t change the root password, because you don’t need to set root password when using unix_socket authentication.
    

Next, you can press Enter to answer all remaining questions, which will remove anonymous user, disable remote root login and remove test database. This step is a basic requirement for MariaDB database security. (Notice that Y is capitalized, which means it is the default answer. )

Enter current password for root (enter for none) → Press Enter  
Switch to unix_socket authenticatton [Y/n] → Press n  
Change the root password? [Υ/n] → Press n  
Remove anonymous users? [Υ/n] → Press Enter  
Disallow root login remotely? [Υ/n] → Press Enter  
Remove test database and access to it? [Υ/n] → Press Enter  
Reload privilege tables now? [Υ/n] → Press Enter

By default, the MariaDB package on Ubuntu uses unix_socket to authenticate user login, which basically means you can use username and password of the OS to log into MariaDB console. So you can run the following command to log in without providing MariaDB root password.

```
sudo mariadb -u root
```

To exit, run

```
exit;
```

## Step 6: Install PHP 8.1 and Configure PHP

Install PHP 8.1 and essential extensions

```
sudo apt install php8.1 php8.1-fpm php8.1-mysql php-common php8.1-cli php8.1-common php8.1-opcache php8.1-readline php8.1-mbstring php8.1-xml php8.1-gd php8.1-curl
```

PHP extensions are commonly needed for content management systems (CMS) like WordPress. For example, if your installation lacks php8.1-xml, then some of your WordPress site pages may be blank and you can find an error in Nginx error log like:

```
PHP message: PHP Fatal error:  Uncaught Error: Call to undefined function xml_parser_create()
```

Installing these PHP extensions ensures that your CMS runs smoothly. Now start php8.1-fpm.

```
sudo systemctl start php8.1-fpm
```

Enable auto start at boot time.

```
sudo systemctl enable php8.1-fpm
```

Check status:

```
systemctl status php8.1-fpm
```

## Step 7: Create Nginx Server Block Configuration

Create a custom Nginx server block configuration for PHP, allowing Nginx to handle PHP files and other static files efficiently.

```
sudo rm /etc/nginx/sites-enabled/default
```

Then use a command-line text editor like Nano to create a new server block file under **/etc/nginx/conf.d/** directory.

```
sudo nano /etc/nginx/conf.d/default.conf
```

Paste the following text into the file. The following snippet will make Nginx listen on IPv4 port 80 and IPv6 port 80 with a catch-all server name.

```
server {
  listen 80;
  listen [::]:80;
  server_name _;
  root /usr/share/nginx/html/;
  index index.php index.html index.htm index.nginx-debian.html;

  location / {
    try_files $uri $uri/ /index.php;
  }

  location ~ \.php$ {
    fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
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
```

Save and close the file.

Then test Nginx configurations.

```
sudo nginx -t
```

If the test is successful, reload Nginx.

```
sudo systemctl reload nginx
```

## Step 8: Improve PHP Performance

The default PHP configurations (/etc/php/8.1/fpm/php.ini) are made for servers with very few resources (like a 256MB RAM server). To improve web application performance, you should change some of them.

We can edit the PHP config file (php.ini), but it’s a good practice to create a custom PHP config file, so when you upgrade to a new version of PHP8.1, your custom configuration will be preserved.

```
sudo nano /etc/php/8.1/fpm/conf.d/60-custom.ini
```

In this file, add the following lines.

```
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
```

Save and close the file. Then reload PHP8.1-FPM for the changes to take effect.

```
sudo systemctl reload php8.1-fpm
```

**OPcache** improves the performance of PHP applications by caching precompiled bytecode. You can view OPcache stats via the info.php page. Below is a before and after comparison on one of my servers.

### Troubleshooting Tip

If you encounter errors, you can check the Nginx error log (/var/log/nginx/error.log) to find out what’s wrong.

## Step 9: Configure Nginx Automatic Restart

If for any reason your Nginx process is killed, you need to run the following command to restart it.

```
sudo systemctl restart nginx
```

Instead of manually typing this command, we can make Nginx automatically restart by editing the nginx.service systemd service unit. To override the default systemd service configuration, we create a separate directory.

```
sudo mkdir -p /etc/systemd/system/nginx.service.d/
```

Then create a file under this directory.

```
sudo nano /etc/systemd/system/nginx.service.d/restart.conf
```

Add the following lines in the file, which will make Nginx automatically restart after **5 seconds** if a failure is detected. The default value of RetartSec is **100ms**, which is too small. Nginx may complain that “start request repeated too quickly” if RestartSec is not big enough.

```
[Service]
Restart=always
RestartSec=5s
```

Save and close the file. Then reload **systemd** for the changes to take effect.

```
sudo systemctl daemon-reload
```

To check if this would work, kill Nginx with:

```
sudo pkill nginx
```

Then check Nginx status. You will find Nginx automatically restarted.

```
systemctl status nginx
```

## Step 10: Configure MariaDB Automatic Restart

By default, MariaDB is configured to automatically restart on-abort (/lib/systemd/system/mariadb.service). However, if your server runs out of memory (oom) and MariaDB is killed by the oom killer, it won’t automatically restart. We can configure it to restart no matter what happens.

Create a directory to store custom configurations.

```
sudo mkdir -p /etc/systemd/system/mariadb.service.d/
```

Create a custom config file.

```
sudo nano /etc/systemd/system/mariadb.service.d/restart.conf
```

Add the following lines in the file.

```
[Service]
Restart=always
RestartSec=5s
```

Save and close the file. Then reload systemd for the changes to take effect.

```
sudo systemctl daemon-reload
```
