#!/bin/bash
set -e

sudo sed -i -e 's/^\(\s*bindIp: 127.0.0.1\)/#\1/' /etc/mongod.conf
sudo systemctl restart mongod
