#!/usr/bin/env bash
scriptname=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")
dirInstall="/opt/drmphp"

function isRoot() {
  if [ $EUID -ne 0 ]; then return 1; fi
}

function getIP() {
  [ -z "$(which dig)" ] && serverIP=$(host myip.opendns.com resolver1.opendns.com | tail -n1 | cut -d' ' -f4-) || serverIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
}

function checkOS() {
  source /etc/os-release
  if [[ $ID != "ubuntu" ]]; then
    echo "This script supports only Ubuntu 18.04, 20.04, or 22.04."
    exit 1
  fi

  MAJOR_UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
  if [[ $MAJOR_UBUNTU_VERSION -lt 18 ]]; then
    echo "Unsupported Ubuntu version. Use Ubuntu 18.04 or newer."
    exit 1
  fi

  echo "Installing required packages..."
  apt-get update -y
  apt-get install -y git software-properties-common iputils-ping dnsutils apache2 mysql-server aria2

  add-apt-repository ppa:ondrej/php -y
  apt-get update -y

  if [[ $MAJOR_UBUNTU_VERSION == 18 ]]; then
    apt-get install -y php7.2 php7.2-cli php7.2-json php7.2-common php7.2-mysql php7.2-zip php7.2-gd php7.2-mbstring php7.2-curl php7.2-xml php7.2-bcmath php7.2-bz2 php7.2-xmlrpc
    phpver="7.2"
  else
    apt-get install -y php7.4 php7.4-cli php7.4-json php7.4-common php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath php7.4-bz2 php7.4-xmlrpc
    phpver="7.4"
  fi
}

function checkArch() {
  case $(uname -m) in
    x86_64) architecture="amd64" ;;
    *) echo "Unsupported architecture."; exit 1 ;;
  esac
}

function checkInternet() {
  if ! ping -c 2 google.com &> /dev/null; then
    echo "No internet connection. Check your network."
    exit 1
  fi
}

function initialCheck() {
  if ! isRoot; then
    echo "Run this script as root or with sudo."
    exit 1
  fi
  checkOS
  checkArch
  checkInternet
}

function installDRMPHP() {
  echo "Installing DRMPHP..."
  mkdir -p "$dirInstall"
  git clone https://github.com/DRM-Scripts/DRMPHP "$dirInstall"

  echo -e "[mysqld]\nsql-mode=\"NO_ENGINE_SUBSTITUTION\"\n" > /etc/mysql/my.cnf
  service mysql restart

  sed -i -r 's/short_open_tag = Off$/short_open_tag = On/' /etc/php/$phpver/cli/php.ini
  sed -i -r 's/short_open_tag = Off/short_open_tag = On/g' /etc/php/$phpver/apache2/php.ini

  read -p "Change DRMPHP web-port? (Yes/No) " answer_cp </dev/tty
  if [[ "$answer_cp" =~ ^[Yy] ]]; then
    read -p "Enter port number: " answer_port </dev/tty
    sed -i "s/80/${answer_port}/" /etc/apache2/ports.conf
    sed -i "s/80/${answer_port}/" /etc/apache2/sites-enabled/000-default.conf
  else
    answer_port="80"
  fi

  echo "www-data ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  service apache2 restart

  if [[ ! -f "/usr/bin/ffmpeg" ]]; then
    echo "Installing ffmpeg..."
    curl -L -o "$dirInstall/ffmpeg.tar.xz" "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
    mkdir -p "$dirInstall/ffmpeg"
    tar -xf "$dirInstall/ffmpeg.tar.xz" -C "$dirInstall/ffmpeg"
    cp "$dirInstall"/ffmpeg/ffmpeg-*-amd64-static/ff* /usr/bin/
  fi

  cp -r "$dirInstall/panel/." /var/www/html
  cd /var/www/html
  chmod +x mp4decrypt
  mkdir -p download backup
  chmod 777 download backup html

  if [ -f /root/.my.cnf ]; then
    read -s -p "Enter MySQL root password: " rootpasswd </dev/tty
  else
    read -p "Create MySQL root password: " rootpasswd </dev/tty
  fi
  echo ""

  read -p "New MySQL database name: " dbname </dev/tty
  sed -i "s/drm/$dbname/g" /var/www/html/_db.php

  read -p "Database character set (default: utf8): " charset </dev/tty
  charset=${charset:-utf8}
  mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${dbname} DEFAULT CHARACTER SET ${charset};"

  read -p "New MySQL user: " username </dev/tty
  sed -i "s/admin/$username/g" /var/www/html/_db.php

  read -s -p "Password for new MySQL user: " userpass </dev/tty
  sed -i "s/passwd/$userpass/g" /var/www/html/_db.php
  echo ""

  mysql -uroot -p${rootpasswd} -e "CREATE USER '${username}'@'localhost' IDENTIFIED BY '${userpass}';"
  mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost'; FLUSH PRIVILEGES;"
  mysql -uroot -p${rootpasswd} ${dbname} < "$dirInstall/db.sql"

  echo "USE $dbname; SET GLOBAL sql_mode = 'NO_ENGINE_SUBSTITUTION'; SET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION';" | mysql -u root -p"$rootpasswd"

  rm -f /var/www/html/index.html
}

function cleanup() {
  rm -rf "$dirInstall"
}

echo ""
echo "#############################################################"
echo "#     DRMPHP install and configuration script for Ubuntu     #"
echo "#############################################################"
echo ""

while true; do
  read -p "This script will install DRMPHP. Continue? (Yes/No) " yn </dev/tty
  case $yn in
    [Yy]*) initialCheck; installDRMPHP; cleanup; break ;;
    [Nn]*) break ;;
    *) echo "Enter Yes or No" ;;
  esac
done

getIP
echo "####################################################"
echo "#                  PANEL DETAILS                   #"
echo "####################################################"
echo "USER: admin"
echo "PASS: Admin@2023##"
echo "URL: http://${serverIP}:${answer_port}/login.php"
echo "----------------------------------------------------"
echo "NOTE: Edit <M3U8 Download URL> in settings page"
echo ""
echo "Have Fun!"
echo ""
sleep 3
