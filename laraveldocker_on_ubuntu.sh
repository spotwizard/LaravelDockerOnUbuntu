#!/bin/bash

# 讀取 JSON 設定檔
CONFIG_FILE="config.json"
TOP_LEVEL_DIR=$(jq -r '.top_level_dir' $CONFIG_FILE)
DB_NAME=$(jq -r '.db_name' $CONFIG_FILE)
DB_USER=$(jq -r '.db_user' $CONFIG_FILE)
DB_PASSWORD=$(jq -r '.db_password' $CONFIG_FILE)
MYSQL_ROOT_PASSWORD=$(jq -r '.mysql_root_password' $CONFIG_FILE)

# 更新 apt 資料庫並安裝必要的套件
sudo apt update
sudo apt install -y curl git unzip apt-transport-https ca-certificates software-properties-common

# 安裝 Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
DEBIAN_FRONTEND=noninteractive sudo apt install -y docker-ce docker-compose

# 建立 Laravel 專屬目錄
mkdir -p $TOP_LEVEL_DIR/app

# 建立 Nginx 專屬目錄
mkdir -p $TOP_LEVEL_DIR/nginx

# 拉取 Laravel 專案碼
cd $TOP_LEVEL_DIR

# 建立 nginx 設定檔
echo 'server {
    listen 80;
    server_name localhost;
    root /var/www/html/public;

    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass laravel_app:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}' > nginx/default.conf

# 建立 docker-compose.yml 檔案
echo "version: '3.8'
services:
  app:
    image: php:8.2-fpm
    container_name: laravel_app
    working_dir: /var/www/html
    volumes:
      - ./app:/var/www/html
    networks:
      - laravel_network

  web:
    image: nginx:latest
    container_name: laravel_web
    ports:
      - '80:80'
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
      - ./app:/var/www/html
    networks:
      - laravel_network

  db:
    image: mysql:8.0
    container_name: laravel_db
    environment:
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_USER
      MYSQL_PASSWORD: $DB_PASSWORD
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - laravel_network

networks:
  laravel_network:
    driver: bridge

volumes:
  db_data:" > docker-compose.yml

# 啟動容器
sudo docker-compose up -d

# 在容器內安裝 PDO 和 MySQL 擴展
sudo docker exec laravel_app sh -c "apt update && apt install -y libpng-dev libjpeg-dev libfreetype6-dev && \
docker-php-ext-configure gd --with-freetype --with-jpeg && \
docker-php-ext-install gd pdo pdo_mysql mysqli"

sudo docker exec laravel_app sh -c "apt update && apt install -y curl unzip && docker-php-ext-install php-zip"

# 在容器內下載 composer
sudo docker exec laravel_app sh -c "curl -s https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer"

# 在容器內下載 laravel
sudo docker exec laravel_app sh -c "composer create-project --prefer-dist laravel/laravel ."

# 在容器內創建 Laravel 資料庫
sudo docker exec laravel_db sh -c "mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'CREATE DATABASE $DB_NAME;'"

# 更新 Laravel 的 .env 檔案以設置資料庫連接
sudo docker exec laravel_app sh -c "sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' /var/www/html/.env && \
sed -i 's/# DB_HOST=.*/DB_HOST=laravel_db/' /var/www/html/.env && \
sed -i 's/# DB_PORT=.*/DB_PORT=3306/' /var/www/html/.env && \
sed -i 's/# DB_DATABASE=.*/DB_DATABASE=$DB_NAME/' /var/www/html/.env && \
sed -i 's/# DB_USERNAME=.*/DB_USERNAME=$DB_USER/' /var/www/html/.env && \
sed -i 's/# DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/' /var/www/html/.env"

# 清除 Laravel 的配置快取
sudo docker exec laravel_app sh -c "php artisan config:cache"

# 設置 Laravel 儲存目錄的權限
sudo docker exec laravel_app sh -c "chmod -R 777 /var/www/html/storage"

# 複製 php.ini-production 為 php.ini
sudo docker exec laravel_app sh -c "cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini"

# 移除 extension=mysqli 和 extension=pdo_mysql 的註解
sudo docker exec laravel_app sh -c "sed -i 's/^;extension=mysqli/extension=mysqli/' /usr/local/etc/php/php.ini && \
sed -i 's/^;extension=pdo_mysql/extension=pdo_mysql/' /usr/local/etc/php/php.ini"

# 重啟 PHP 容器
sudo docker restart laravel_app

# 建立初始資料表
sudo docker exec laravel_app sh -c "php artisan migrate"

# 顯示完成訊息
echo "Laravel 網站已成功建置，請在瀏覽器中訪問 http://localhost"
