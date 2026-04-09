#!/bin/bash

SERVER_PORT=51820
SERVER_IP=$(curl -s4 ifconfig.co)
WG_INTERFACE="wg0"
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)
CLIENT_PRE_SHARED_KEY=$(wg genpsk)

cat <<EOF > /etc/wireguard/$WG_INTERFACE.conf
[Interface]
Address = 10.5.0.1/24, fddd:2c4:2c4:2c4::1/64
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_PRIVATE_KEY

PostUp = iptables -A FORWARD -i $WG_INTERFACE -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostUp = ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o sit1 -j MASQUERADE
PostDown = iptables -D FORWARD -i $WG_INTERFACE -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PostDown = ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o sit1 -j MASQUERADE
EOF

cat <<EOF >> /etc/wireguard/$WG_INTERFACE.conf

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.5.0.2/32, fddd:2c4:2c4:2c4::2/128
PresharedKey = $CLIENT_PRE_SHARED_KEY
EOF

cat <<EOF > /etc/wireguard/client.conf
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.5.0.2/24, fddd:2c4:2c4:2c4::2/64
DNS = 208.67.222.222, 2620:119:35::35, 208.67.220.220, 2620:119:53::53

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:$SERVER_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PresharedKey = $CLIENT_PRE_SHARED_KEY
PersistentKeepalive = 25
EOF

systemctl enable wg-quick@$WG_INTERFACE
systemctl start wg-quick@$WG_INTERFACE

echo "Setup done"
echo "The client conf file is saved in /etc/wireguard/client.conf"
