#!/bin/sh

# Функция для вывода зеленого текста
print_green() {
    echo -e "\033[0;32m$1\033[0m"
}

# Печать стартового сообщения
print_green "Начинаю установку и настройку WireGuard..."

# Обновление списка пакетов
print_green "Обновляю список пакетов..."
opkg update

# Установка пакетов WireGuard, если они ещё не установлены
print_green "Устанавливаю необходимые пакеты..."
opkg install kmod-wireguard wireguard-tools

# Проверка установки WireGuard
if [ $? -ne 0 ]; then
    print_green "Ошибка установки WireGuard!"
    exit 1
fi

# Создание нового интерфейса WireGuard
print_green "Создаю новый интерфейс WireGuard..."

cat <<EOF > /etc/config/network
# Новый интерфейс WireGuard
config interface 'wg0'
    option proto 'wireguard'
    option private_key 'wKb8VjRNAcoECcFVlE89ZGh1YXgJ1FzPEB9Fz+QjGGI='
    option address '10.0.0.2/32'
    option dns '1.1.1.1 1.0.0.1'
    option mtu '1420'

# Настройки Peer для подключения к серверу WireGuard
config wireguard_wg0
    option public_key 'uT3Lie41LK5MNVrWDM4NkR8vX7q4ZEnJuHRdQ1fZgVw='
    option allowed_ips '0.0.0.0/0, ::/0'
    option endpoint_host 'owrtrouters.kv9.ru'
    option endpoint_port '27988'
    option preshared_key 'vTdc1+h1IDUoP++dTDo+7BaL4HwlMLzgbnfK6rCdT9A='
    option persistent_keepalive '25'
EOF

# Перезапуск сети для применения изменений
print_green "Перезапускаю сеть..."
/etc/init.d/network restart

# Проверка статуса WireGuard
print_green "Проверяю статус WireGuard..."
wg show

# Настройка автозапуска интерфейса WireGuard
print_green "Настроено на автозапуск WireGuard при старте системы..."
/etc/init.d/network enable

# Конечное сообщение
print_green "WireGuard настроен и подключение будет автоматически восстанавливаться!"

# Вывод статуса
wg show
