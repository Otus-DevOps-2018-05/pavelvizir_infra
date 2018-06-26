#!/bin/bash
set -e
set -x
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
