#!/usr/bin/env bash

mapfile  -t mcx_bus < <(lspci -Dnn | grep -iw 15b3 | awk '{print $1}' 2>/dev/null)

for bus in "${mcx_bus[@]}";do
  mlxfwreset -d $bus reset -y
done