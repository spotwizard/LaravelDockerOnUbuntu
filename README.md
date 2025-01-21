# Laravel Docker on Ubuntu

本程式的功能為在 Ubuntu 上一鍵自動化安裝 Docker、Docker Composer，並建立 PHP-Nginx-MySQL 環境的 Laravel 網站。

## 環境需求

- Ubuntu 18.04 或以上
- `jq`：用於解析 JSON 設定檔
- `curl`：用於下載必要的檔案

## 使用方法

1. **下載程式**

   ```bash
   git clone https://github.com/spotwizard/LaravelDockerOnUbuntu.git /path/to/your/scripts
   ```

2. **準備設定檔**

   建立名為 `config.json` 的檔案，並填入以下內容：

   ```json
   {
       "top_level_dir": "/path/to/your/project",
       "db_name": "your_database_name",
       "db_user": "your_database_user",
       "db_password": "your_database_password",
       "mysql_root_password": "your_mysql_root_password"
   }
   ```

   請根據需求修改以上內容。

3. **賦予執行權限**

   在終端中運行以下命令以賦予執行權限：

   ```bash
   chmod +x laraveldocker_on_ubuntu.sh
   ```

4. **執行程式**

   使用以下命令執行程式：

   ```bash
   sh laraveldocker_on_ubuntu.sh
   ```

   將會自動安裝 Docker、Docker Compose，並設定 Laravel 環境。

## 功能

- 讀取 JSON 設定檔以取得參數
- 安裝必要的系統套件
- 安裝 Docker 和 Docker Compose
- 建立 Laravel 專案目錄
- 設定 Nginx 和 Docker Compose
- 安裝 PHP 套件
- 下載 Composer 並安裝 Laravel
- 建立 MySQL 資料庫供 Laravel 存取
- 設定 Laravel 儲存目錄的權限
- 建立初始資料表

## 注意事項

- 請確認 Docker 和 Docker Compose 正常運行。
- 在執行前，請檢查 `config.json` 中的參數值是否正確。
