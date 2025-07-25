#!/usr/bin/env bash

if command -v curl > /dev/null; then
    sudo curl https://teal.terascripting.com/public/distrousurp/distrousurp -o distrousurp
elif command -v wget > /dev/null; then
    sudo wget https://teal.terascripting.com/public/distrousurp/distrousurp -O distrousurp
else
    exit 1
fi

DISTRO="RockyLinux9"

sudo chmod +x distrousurp
printf "vagrant\nvagrant\nvagrant\n" | sudo ./distrousurp fetch $DISTRO
sudo ./distrousurp boot