#!/bin/sh

WG_CONF_PATH="/etc/wireguard/wg0.conf"
WG_INTERFACE="wg0"

echo "=== Проверка наличия WireGuard ==="
if ! command -v wg > /dev/null; then
    echo "WireGuard не установлен. Устанавливаем..."
    opkg update
    opkg install wireguard-tools kmod-wireguard
else
    echo "WireGuard уже установлен."
fi

echo "=== Настройка конфигурации WireGuard ==="
mkdir -p /etc/wireguard

# Проверяем, есть ли конфигурационный файл vps.conf в текущей папке
if [ ! -f "vps.conf" ]; then
    echo "Ошибка: Файл vps.conf не найден!"
    exit 1
fi

# Копируем конфигурацию в нужное место
cp vps.conf $WG_CONF_PATH
chmod 600 $WG_CONF_PATH

echo "=== Запуск WireGuard ==="
wg-quick down $WG_INTERFACE 2>/dev/null
wg-quick up $WG_INTERFACE

echo "=== Настройка автозапуска ==="
uci set network.$WG_INTERFACE=interface
uci set network.$WG_INTERFACE.proto='wireguard'
uci commit network

# Добавляем WireGuard в автозапуск
if ! grep -q "wg-quick up $WG_INTERFACE" /etc/rc.local; then
    sed -i "/exit 0/i wg-quick up $WG_INTERFACE" /etc/rc.local
fi

echo "=== Проверка соединения ==="
sleep 5  # Даем немного времени на установление соединения
WG_PEER_IP=$(grep -oP '(?<=AllowedIPs = )[^/]+' $WG_CONF_PATH)
ping -c 4 $WG_PEER_IP

if [ $? -eq 0 ]; then
    echo "VPN соединение успешно установлено!"
else
    echo "Ошибка: Нет ответа от сервера VPN!"
    exit 1
fi

echo "=== Настройка маршрутизации ==="
# Разрешаем доступ в локальную сеть (например, 192.168.1.0/24)
uci add_list network.$WG_INTERFACE.allowed_ips='192.168.1.0/24'
uci commit network
/etc/init.d/network restart

echo "=== Готово! WireGuard настроен и работает ==="
