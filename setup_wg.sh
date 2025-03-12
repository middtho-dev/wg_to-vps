#!/bin/bash

# Функция для вывода сообщений в зелёном цвете
log_green() {
    echo -e "\033[32m$1\033[0m"
}

# 1. Установка WireGuard
log_green "Проверка наличия WireGuard..."
opkg update
opkg install wireguard

if [ $? -eq 0 ]; then
    log_green "WireGuard успешно установлен."
else
    log_green "Ошибка установки WireGuard!"
    exit 1
fi

# 2. Настройка конфигурации
log_green "Настройка конфигурации WireGuard..."

# Путь к файлу конфигурации
WG_CONFIG="/etc/config/network"

# Сохранение конфигурации из переменной в файл
cat <<EOF > $WG_CONFIG
config interface 'wg0'
    option proto 'wireguard'
    option private_key 'wKb8VjRNAcoECcFVlE89ZGh1YXgJ1FzPEB9Fz+QjGGI='
    option address '10.0.0.2/32'
    option dns '1.1.1.1 1.0.0.1'
    option mtu '1420'

config wireguard_wg0
    option public_key 'uT3Lie41LK5MNVrWDM4NkR8vX7q4ZEnJuHRdQ1fZgVw='
    option allowed_ips '0.0.0.0/0, ::/0'
    option endpoint_host 'owrtrouters.kv9.ru'
    option endpoint_port '27988'
    option preshared_key 'vTdc1+h1IDUoP++dTDo+7BaL4HwlMLzgbnfK6rCdT9A='
EOF

# 3. Обновление маршрутов
log_green "Обновление маршрутов..."

# Добавляем статические маршруты для подключения
uci set network.wg0.route='0.0.0.0/0'
uci set network.wg0.route6='::/0'
uci commit network

# 4. Настройка автозапуска
log_green "Настройка автозапуска WireGuard..."

uci set system.@system[0].reboot='1'
uci commit system

# 5. Включение интерфейса WireGuard
log_green "Включение интерфейса WireGuard..."

ifup wg0

if [ $? -eq 0 ]; then
    log_green "WireGuard интерфейс успешно включен."
else
    log_green "Ошибка при включении интерфейса WireGuard!"
    exit 1
fi

# 6. Проверка подключения
log_green "Проверка состояния соединения WireGuard..."

wg show wg0

log_green "Настройка завершена. WireGuard настроен и подключен!"
exit 0
