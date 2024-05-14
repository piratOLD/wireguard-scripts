#!/bin/bash

# Передаем номер клиента как аргумент скрипту
client_num="$1"

# Генерируем ключи для клиентов и сохраняем их в файлах с номером
wg genkey | tee "/etc/wireguard/keys/client${client_num}_private_key" | wg pubkey > "/etc/wireguard/keys/client${client_num}_public_key"

# Путь к конфигурационному файлу сервера WireGuard
server_config="/etc/wireguard/wg0.conf"

# Функция для добавления пиров (клиентов)
add_peer() {
    client_num="$1"
    
    client_name="client${client_num}"

    # Создаем секцию пира для клиента
    cat >> "$server_config" <<EOL
[Peer]
PublicKey = $(cat "/etc/wireguard/keys/client${client_num}_public_key")
AllowedIPs = 10.7.0.${client_num}/32, fddd:2c4:2c4:2c4::${client_num}/128
# Дополнительные параметры пира (по желанию)
EOL

    # Создаем файл конфигурации для клиента с номером
    client_config_file="/etc/wireguard/clients/$client_name.conf"
    cat > "$client_config_file" <<EOL
[Interface]
PrivateKey = $(cat "/etc/wireguard/keys/client${client_num}_private_key")   # Приватный ключ клиента
Address = 10.7.0.${client_num}/24, fddd:2c4:2c4:2c4::${client_num}/64
DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001

[Peer]
PublicKey = $(cat "publicServ.key")   # Публичный ключ сервера
Endpoint =    # Адрес сервера и порт
AllowedIPs = 0.0.0.0/0, ::/0
# Дополнительные параметры сервера (по желанию)
EOL

    # Выводим информацию о добавленном пире
    echo "Peer '$client_name' added to server config."
    echo "Client config file saved to: $client_config_file"
}

# Использование: ./add_peer.sh <номер_клиента>
add_peer "$client_num"
