#!/bin/bash
port_regex="\:([0-9]{4})"
token_regex="[0-9a-z]{48}"
docker ps --format '{{.Names}}' | while read -r line ; do
  res=$(docker container port $line)
  [[ $res =~ $port_regex ]]
  port=${BASH_REMATCH[1]}
  res2=$(docker exec $line sh -c "jupyter notebook list")
  [[ $res2 =~ $token_regex ]]
  token=$BASH_REMATCH
  ip=$(host myip.opendns.com resolver1.opendns.com | grep "myip.opendns.com has" | awk '{print $4}')
  echo
  echo "Connection Command: ssh -L ${port}:localhost:${port} opc@${ip}"
  echo "Then navigate with browser: http://localhost:${port}/?token=${token}"
  echo
  echo "__________________________________________________________"
done
