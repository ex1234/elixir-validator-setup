#!/bin/bash

# Установка Docker и Python без подтверждений
export DEBIAN_FRONTEND=noninteractive

# Предустановка параметров конфигурации для debconf
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
echo 'debconf debconf/priority select critical' | sudo debconf-set-selections

# Установка Docker и Python
sudo apt-get update
sudo apt-get install -y docker.io python3 python3-pip

# Установка необходимых Python библиотек
pip3 install web3 ecdsa

# Генерация приватного ключа
generate_private_key() {
    openssl rand -hex 32
}

# Создание Python скрипта для генерации адреса
cat << 'EOF' > generate_address.py
import sys
import binascii
from web3 import Web3
from eth_keys import keys

def private_key_to_address(private_key):
    private_key_bytes = binascii.unhexlify(private_key)
    public_key = keys.PrivateKey(private_key_bytes).public_key
    return public_key.to_checksum_address()

private_key = sys.argv[1]
address = private_key_to_address(private_key)
print(address)
EOF

# Генерация приватного ключа и адреса
PRIVATE_KEY=$(generate_private_key)
ADDRESS=$(python3 generate_address.py $PRIVATE_KEY)

# Генерация имени ноды
generate_node_name() {
    local length=8
    tr -dc a-z </dev/urandom | head -c $length
}

NODE_NAME=$(generate_node_name)

# Создание Dockerfile
cat <<EOF > Dockerfile
FROM elixirprotocol/validator:testnet-2

ENV ADDRESS=$ADDRESS
ENV PRIVATE_KEY=$PRIVATE_KEY
ENV VALIDATOR_NAME=$NODE_NAME
EOF

# Построение и запуск Docker контейнера
sudo docker build -t elixir-validator .
sudo docker run -d --restart unless-stopped --name elixir-validator elixir-validator

echo "Private Key: $PRIVATE_KEY"
echo "Address: $ADDRESS"
echo "Node Name: $NODE_NAME"
echo "Dockerfile created and container started successfully."
