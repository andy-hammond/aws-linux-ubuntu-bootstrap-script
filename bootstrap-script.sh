#!/bin/bash

# install essential packages
sudo su
apt-get update -y
apt-get install -y apache2 php7.0 php7.0-dev unixodbc-dev mcrypt php7.0-mcrypt php-pear libapache2-mod-php php7.0-mbstring php7.0-xml php7.0-curl ruby wget sysv-rc-conf git-core composer npm nfs-common libpng16-dev

# mount EFS onto apache root (optional)
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 [AWS_EFS_NAME]:/ /var/www/html

# Allow apache override for laravel
sudo a2enmod rewrite
sudo sed -i -e '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# start apache server & ensure restarts whenever server does
sudo service apache2 start
sudo sysv-rc-conf apache2 on

# create apache virtual host configuration for each website

:'
Add the below into each virtual host to redirect to SSL protocol (optional):

    RewriteEngine On
    RewriteCond %{HTTP:X-Forwarded-Proto} =http
    RewriteRule .* https://%{HTTP:Host}%{REQUEST_URI} [L,R=permanent]

'

sudo echo "
<VirtualHost *:80>
    ServerAdmin support@example.com
    ServerName example.com
    ServerAlias example.com www.example.com
    DocumentRoot /var/www/html/www/
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
" > /etc/apache2/sites-available/www.conf

sudo echo "
<VirtualHost *:80>
    ServerAdmin support@example.com
    ServerName sub1.example.com
    ServerAlias sub1.example.com
    DocumentRoot /var/www/html/sub1/
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
" > /etc/apache2/sites-available/sub1.conf

sudo echo "
<VirtualHost *:80>
    ServerAdmin support@example.com
    ServerName sub2.example.com
    ServerAlias sub2.example.com
    DocumentRoot /var/www/html/sub2/
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
" > /etc/apache2/sites-available/sub2.conf


# Enable sites

a2ensite www.conf
a2ensite sub1.conf
a2ensite sub2.conf

sudo service apache2 restart

# install msodbc driver(s) (optional)
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

sudo apt-get update -y
sudo ACCEPT_EULA=Y apt-get install msodbcsql mssql-tools -y
sudo apt-get install unixodbc-dev -y
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

sudo pear config-set php_ini `php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||"` system
sudo pecl install sqlsrv
sudo pecl install pdo_sqlsrv

sudo echo "
extension=pdo.so
extension=sqlsrv.so
extension=pdo_sqlsrv.so
" >> /etc/php/7.0/apache2/php.ini

sudo service apache2 restart

# install nodejs (optional)
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
apt-get install -y nodejs
node -v
npm install npm --global

# install AWS CodeDeploy Agent (optional)
wget https://aws-codedeploy-eu-west-2.s3.amazonaws.com/latest/install
chmod +x ./install
./install auto
sudo service codedeploy-agent start
