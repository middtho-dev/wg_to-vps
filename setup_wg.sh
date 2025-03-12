#!/bin/sh

# Убедимся, что установлены все нужные пакеты
echo -e "\033[32mПроверка наличия необходимых пакетов...\033[0m"
opkg update
opkg list-installed | grep wireguard
if [ $? -ne 0 ]; then
    echo -e "\033[32mWireGuard не найден, устанавливаем необходимые пакеты...\033[0m"
    opkg install kmod-wireguard wireguard-tools
else
    echo -e "\033[32mWireGuard уже установлен.\033[0m"
fi

# Директория для конфигурации WireGuard
WG_CONFIG_DIR="/etc/wireguard"
mkdir -p $WG_CONFIG_DIR

# Путь к конфигурационному файлу
WG_CONFIG_FILE="$WG_CONFIG_DIR/vps.conf"

# Запишем конфигурацию в файл
echo -e "\033[32mЗапись конфигурации WireGuard в файл $WG_CONFIG_FILE...\033[0m"
cat <<EOF > $WG_CONFIG_FILE
[Interface]
PrivateKey = wKb8VjRNAcoECcFVlE89ZGh1YXgJ1FzPEB9Fz+QjGGI=
Address = 10.0.0.2/32
DNS = 1.1.1.1, 1.0.0.1
MTU = 1420

[Peer]
PublicKey = uT3Lie41LK5MNVrWDM4NkR8vX7q4ZEnJuHRdQ1fZgVw=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = owrtrouters.kv9.ru:27988
PresharedKey = vTdc1+h1IDUoP++dTDo+7BaL4HwlMLzgbnfK6rCdT9A=
EOF

echo -e "\033[32mКонфигурация успешно записана.\033[0m"

# Конфигурация интерфейса WireGuard
echo -e "\033[32mСоздание конфигурации интерфейса WireGuard...\033[0m"
cat <<EOF > /etc/config/network
config interface 'wg0'
    option proto 'wireguard'
    option private_key 'wKb8VjRNAcoECcFVlE89ZGh1YXgJ1FzPEB9Fz+QjGGI='
    option listen_port '51820'
    list addresses '10.0.0.2/32'

config wireguard_wg0
    option public_key 'uT3Lie41LK5MNVrWDM4NkR8vX7q4ZEnJuHRdQ1fZgVw='
    option endpoint_host 'owrtrouters.kv9.ru'
    option endpoint_port '27988'
    option preshared_key 'vTdc1+h1IDUoP++dTDo+7BaL4HwlMLzgbnfK6rCdT9A='
    list allowed_ips '0.0.0.0/0'
    list allowed_ips '::/0'
    option persistent_keepalive '25'
EOF

echo -e "\033[32mКонфигурация интерфейса создана.\033[0m"

# Очищаем старые маршруты, чтобы избежать конфликтов
echo -e "\033[32mУдаляем старые маршруты...\033[0m"
ip route flush table main

# Запуск интерфейса WireGuard
echo -e "\033[32mЗапускаем интерфейс WireGuard...\033[0m"
ifup wg0

# Убедимся, что соединение установлено
echo -e "\033[32mПроверка соединения...\033[0m"
ping -c 4 10.0.0.1

if [ $? -eq 0 ]; then
    echo -e "\033[32mПодключение успешно установлено!\033[0m"
else
    echo -e "\033[31mОшибка подключения.\033[0m"
    exit 1
fi

# Настройка маршрутов для доступа к роутеру и сети LAN
echo -e "\033[32mНастройка маршрутов...\033[0m"

# Необходимо добавить маршрут для доступа к локальной сети и маршрутизатору
ip route add 192.168.1.0/24 dev eth0
ip route add 10.0.0.0/32 dev wg0
ip route add default via 192.168.1.1

echo -e "\033[32mМаршруты настроены.\033[0m"

# Убедимся, что интерфейс поднимется после перезагрузки
echo -e "\033[32mНастройка автозапуска интерфейса...\033[0m"
uci set network.wg0=interface
uci set network.wg0.proto='wireguard'
uci set network.wg0.private_key='wKb8VjRNAcoECcFVlE89ZGh1YXgJ1FzPEB9Fz+QjGGI='
uci commit network

echo -e "\033[32mАвтозапуск настроен.\033[0m"

# Перезагружаем сеть
echo -e "\033[32mПерезагрузка сети...\033[0m"
/etc/init.d/network restart

echo -e "\033[32mСкрипт выполнен успешно.\033[0m"
