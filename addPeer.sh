#!/bin/bash

WG_INTERFACE="wg0"
SERVER_IP=$(curl -s4 ifconfig.co)
SERVER_PORT=51820

read -p "New name peer: " CLIENT_NAME
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)
CLIENT_PRE_SHARED_KEY=$(wg genpsk)
CLIENT_IP="10.5.0.$(( $(wg show $WG_INTERFACE allowed-ips | wc -l) + 2 ))"
CLIENT_IPV6="fddd:2c4:2c4:2c4::$(( $(wg show $WG_INTERFACE allowed-ips | wc -l) + 2 ))"

cat <<EOF >> /etc/wireguard/$WG_INTERFACE.conf

[Peer]
# $CLIENT_NAME
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP/32, $CLIENT_IPV6/128
PresharedKey = $CLIENT_PRE_SHARED_KEY
EOF

CLIENT_CONF="/etc/wireguard/clients/$CLIENT_NAME.conf"
mkdir -p /etc/wireguard/clients
cat <<EOF > $CLIENT_CONF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24, $CLIENT_IPV6/64
DNS = 208.67.222.222, 208.67.220.220, 2620:119:35::35, 2620:119:53::53

[Peer]
PublicKey = $(cat /etc/wireguard/$WG_INTERFACE.conf | grep "PrivateKey" | awk '{print $3}' | wg pubkey)
Endpoint = $SERVER_IP:$SERVER_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PresharedKey = $CLIENT_PRE_SHARED_KEY
PersistentKeepalive = 25
EOF

systemctl restart wg-quick@wg0

echo "Peer $CLIENT_NAME added successfully!"
echo "The peer conf is saved in $CLIENT_CONF"
