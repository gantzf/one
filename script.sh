#!/bin/bash

# Устанавливаем fail2ban и ufw
echo "Устанавливаем fail2ban и ufw mc git docker.io docker-compose-v2"
sudo apt update && sudo apt dist-upgrade -y
sudo apt install -y fail2ban ufw mc git docker.io docker-compose-v2 net-tools unzip

# Предлагаем сменить порт SSH
echo "Введите новый порт для SSH (по умолчанию 2222):"
read NEW_SSH_PORT
NEW_SSH_PORT=${NEW_SSH_PORT:-2222}

# Меняем порт SSH
echo "Смена порта SSH на $NEW_SSH_PORT..."

# Открываем конфигурацию SSH
sudo sed -i "s/^#Port 22/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config

# Перезапускаем SSH для применения изменений
sudo systemctl restart sshd

# Добавляем новый порт SSH в ufw
echo "Открываем новый порт SSH в ufw..."
sudo ufw limit $NEW_SSH_PORT/tcp

# Закрываем старый порт SSH (по умолчанию 22)
echo "Закрываем старый порт 22 в ufw..."
sudo ufw deny 22/tcp

# Применяем изменения в ufw
sudo ufw enable
sudo ufw reload

echo "Создайте ключи на клиенте и скопируйте их на сервер и настройте доступ только по ключам"

# Настройка fail2ban

# Открываем конфигурацию для ssh
echo "Настроим fail2ban для работы с новым портом SSH..."

# Создаем копию default конфигурации для SSH
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Редактируем файл jail.local для нового порта
sudo sed -i "s/^port = ssh/port = $NEW_SSH_PORT/" /etc/fail2ban/jail.local

# Перезапускаем fail2ban для применения изменений
sudo systemctl restart fail2ban

# Проверим статус fail2ban
echo "Проверяем статус fail2ban..."
sudo systemctl status fail2ban

# Настроим ufw для блокировки всех ненужных портов
echo "Открываем только необходимые порты в ufw и блокируем остальные..."

# Разрешаем только порты для SSH, HTTP (80), HTTPS (443)
sudo ufw allow 443/tcp
sudo ufw allow 6443/tcp
sudo ufw allow 2083/udp

# Закрываем порты, которые часто сканируются и могут быть уязвимыми
echo "Блокируем часто сканируемые порты..."

# Блокируем порты 21 (FTP), 23 (Telnet), 25 (SMTP), 53 (DNS), 110 (POP3), 143 (IMAP), 3389 (RDP), 5900 (VNC)
sudo ufw deny 21/tcp
sudo ufw deny 23/tcp
sudo ufw deny 25/tcp
sudo ufw deny 53/tcp
sudo ufw deny 53/udp
sudo ufw deny 110/tcp
sudo ufw deny 143/tcp
sudo ufw deny 3389/tcp
sudo ufw deny 5900/tcp

# Блокируем все остальные порты
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Перезапускаем ufw для применения изменений
sudo ufw reload

# Включаем BBR (Bottleneck Bandwidth and RTT)
echo "Включаем BBR..."

# Проверяем, поддерживает ли ядро BBR

# Включаем BBR, добавляем параметры в sysctl.conf
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf

# Применяем изменения для активации BBR
sudo sysctl -p

# Проверяем, что BBR активирован
echo "Проверяем статус BBR..."
sysctl net.ipv4.tcp_congestion_control


# Отключаем стандартный DNS-сервер для работы с Pi-hole
echo "Отключаем стандартный DNS..."

# Отключаем systemd-resolved (для систем, где он используется)
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

sudo rm -r /etc/resolv.conf && sudo touch /etc/resolv.conf
# Отключаем DNS-серверы в resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null

# Переходим на использование Pi-hole
echo "Теперь сервер сможет использовать Pi-hole для DNS..., но не забудь заменить адрес на 127.0.0.1 после установки pihole"

echo "добавим пользователя в группу Docker"
sudo usermod -aG docker $USER
newgrp docker

echo "Добавим сеть в докер dns_net"
docker network create --driver bridge --subnet=192.168.210.0/26 dns_net

echo "Настройка завершена! Теперь можем перейти к запуску нашей компос файла"

