#!/bin/bash

# Устанавливаем WireGuard
echo -e "\033[32m[INFO] Устанавливаю WireGuard...\033[0m"
opkg update
opkg install wireguard

# Проверка установки WireGuard
if ! command -v wg &> /dev/null
then
    echo -e "\033[31m[ERROR] WireGuard не установлен. Завершаю выполнение скрипта.\033[0m"
    exit 1
fi

# Создаем конфигурацию для интерфейса
WG_CONF_PATH="/etc/config/wireguard"
echo -e "\033[32m[INFO] Создаю конфигурацию для интерфейса...\033[0m"

cat <<EOL > $WG_CONF_PATH
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
    option persistent_keepalive '25'
EOL

# Перезагружаем сетевые интерфейсы
echo -e "\033[32m[INFO] Перезагружаю сетевые интерфейсы...\033[0m"
/etc/init.d/network restart

# Настроим автозапуск WireGuard
echo -e "\033[32m[INFO] Включаю автозапуск WireGuard...\033[0m"
/etc/init.d/network enable

# Проверка статуса подключения WireGuard
echo -e "\033[32m[INFO] Проверяю статус соединения...\033[0m"
wg show wg0

# Логирование успешной установки
echo -e "\033[32m[INFO] WireGuard успешно установлен и настроен.\033[0m"
echo -e "\033[32m[INFO] Соединение будет постоянно включено.\033[0m"

# Выводим информацию о сетевых интерфейсах
echo -e "\033[32m[INFO] Просмотр сетевых интерфейсов...\033[0m"
ip addr show
