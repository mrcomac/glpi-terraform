#!/bin/sh
echo "Installing NGINX and PHP-FPM"

#sudo tail --pid=$(ps -ef | grep -v grep | grep yum | head -1 | awk '{print $2}') -f /dev/null 2> /dev/null
sudo amazon-linux-extras install nginx1 php7.3 -y
#sudo tail --pid=$(ps -ef | grep -v grep | grep yum | head -1 | awk '{print $2}') -f /dev/null 2> /dev/null
sudo yum install  php-ldap php-opcache php-apcu php-zend php-xmlrpc \
                  php-sodium php-mysqli php-curl php-fileinfo php-gd \
                  php-mbstring php-cli php-zlib php-xml php-intl \
                  php-simplexml php-cli -y

echo "Installing GLPI"
sudo wget https://github.com/glpi-project/glpi/releases/download/9.5.3/glpi-9.5.3.tgz
sudo tar -xvzf glpi-9.5.3.tgz > /dev/null
sudo cp -r glpi /usr/share/nginx/html/ > /dev/null
sudo chown nginx:apache /usr/share/nginx/html/glpi -R
sudo chmod 775 /usr/share/nginx/html/glpi -R

sudo tee /etc/nginx/conf.d/glpi.conf << EOF
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /usr/share/nginx/html/glpi;
        index index.php;

        server_name _;

        location / {
                try_files \$uri \$uri/ =404;
        }
        location /files/_log {
                deny all;
        }
        location ~* \.php\$ {
                fastcgi_index   index.php;
                fastcgi_pass    unix:/run/php-fpm/www.sock;
                include         fastcgi_params;
                fastcgi_param  SERVER_NAME        \$host;
                fastcgi_param   SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
                fastcgi_param   SCRIPT_NAME        \$fastcgi_script_name;
        }
}
EOF

sudo echo "" > /etc/nginx/nginx.conf
sudo tee /etc/nginx/nginx.conf << EOF
# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;


}
EOF

echo "Starting NGINX and PHP-FPM"

sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
