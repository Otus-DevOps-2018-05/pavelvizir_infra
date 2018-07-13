#!/usr/bin/env bash
if [ "$1" == "--list" ] ; then
  cat inventory.json
elif [ "$1" == "--host" ]; then
  echo '{"_meta": {"hostvars": {}}}'
else
  echo "{ }"
fi
