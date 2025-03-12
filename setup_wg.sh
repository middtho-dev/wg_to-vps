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

# Проверка наличия wg-quick
if ! command -v wg-quick > /dev/null; then
    echo "wg-quick отсутствует. Устанавливаем..."
    opkg install wireguard-tools
fi

echo "=== Настройка конфигурации WireGuard ==="
mkdir -p /etc/wireguard

# Проверяем, есть ли конфигурационный файл vps.conf
if [ ! -f "vps.conf" ]; then
    echo "Ошибка: Файл vps.conf не найден!"
    exit 1
fi

# Копируем конфигурацию
cp vps.conf $WG_CONF_PATH
chmod 600 $WG_CONF_PATH

echo "=== Запуск WireGuard ==="
wg-quick down $WG_INTERFACE 2>/dev/null
wg-quick up $WG_INTERFACE

echo "=== Настройка автозапуска ==="
uci set network.$WG_INTERFACE=interface
uci set network.$WG_INTERFACE.proto='wireguard'
uci commit network

# Добавляем в автозапуск
if ! grep -q "wg-quick up $WG_INTERFACE" /etc/rc.local; then
    sed -i "/exit 0/i wg-quick up $WG_INTERFACE" /etc/rc.local
fi

echo "=== Проверка соединения ==="
sleep 5  # Даем немного времени на установление соединения

# Ищем IP-адрес сервера в конфиге (без `-P`, так как busybox не поддерживает)
WG_PEER_IP=$(grep 'AllowedIPs' $WG_CONF_PATH | cut -d ' ' -f 3 | cut -d '/' -f 1)

if [ -z "$WG_PEER_IP" ]; then
    echo "Ошибка: Не удалось определить IP сервера из конфига!"
    exit 1
fi

# Проверяем пинг
ping -c 4 "$WG_PEER_IP" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "VPN соединение успешно установлено!"
else
    echo "Ошибка: Нет ответа от сервера VPN!"
    exit 1
fi

echo "=== Настройка маршрутизации ==="
uci add_list network.$WG_INTERFACE.allowed_ips='192.168.1.0/24'
uci commit network
/etc/init.d/network restart

echo "=== Готово! WireGuard настроен и работает ==="
