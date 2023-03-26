#!/usr/bin/env bash

### 远程拷贝固件

### 工具安装优化
install_mft() {
  mft_kernel=$(ls ./mft | grep `uname -r | tr '-' '_'`)
  rpm -ivh ./mft/$mft_kernel > /dev/null 2>&1
  rpm -ivh ./*.rpm > /dev/null 2>&1
}

compare_version() {
  if [[ $1 < $2 ]];then
    echo 1
  fi
}


if [ -f mcx_bus.txt ];then
  rm -rf  mcx_bus.txt
fi

mapfile  -t mcx_options < <(lspci -Dnn | grep -iw 15b3 2>/dev/null)

for mcx_option in "${mcx_options[@]}";do
  echo $mcx_option | awk '{print $1}' | cut -d: -f2 >> mcx_bus.txt
done

if [ -f option_lists.txt ];then
  rm -rf  option_lists.txt
fi
dev_cnt=1
for bus in $(cat mcx_bus.txt | sort -u );do
  dev_and_ven=$(lspci -Dnn | grep 0000:$bus:00.0 | awk '{print $NF}' | cut -d[ -f2 | cut -d] -f1 | tr ':' ',')
  subid=$(setpci -s 0000:$bus:00.0 2c.l)
  subven=${subid:4:8}
  subdev=${subid:0:4}
  option_name=$(cat repo_info.txt | grep -w "$dev_and_ven,$subven,$subdev" |awk '{print $1}')

  install_mft
  mst start > /dev/null 2>&1
  
  if [ $? == 0 ];then
    mst_dev=$(mst status | grep -B2 0000:$bus:00.0 | grep -E '/dev/mst/' | awk -F " " '{print $1}')
    echo "ID:$dev_cnt  $option_name  $bus  $mst_dev" >> ./option_lists.txt
  else
    echo "please install mft tool"
  fi
  let dev_cnt=dev_cnt+1
done


# mellanox firmware downgrade
mellanox_downgrade() {
  if [[ -f option_lists.txt  && `cat option_lists.txt | wc -l` != 0  ]];then
    echo "=====================Update list:========================="
    cat ./option_lists.txt
    echo "=========================================================="
  fi

  read -p "Please input option ID for update: " option_ids

  for id in $option_ids;do
    mellanox_dev=$(cat ./option_lists.txt | grep -w "ID:$id" | awk '{print $NF}')
    bus=$(cat ./option_lists.txt | grep "ID:$id" | awk '{print $3}')
    option=$(cat ./option_lists.txt | grep "ID:$id" | awk '{print $2}')
    net_port=$(ls /sys/bus/pci/devices/0000:$bus:00.0/net)
    current_version=$(ethtool -i $net_port | grep -i 'firmware-version' | awk '{print $2}' | awk -F '/' '{print $1}')

    if [[ current_version != '' ]];then

      mapfile  -t fw_list < <(ls ./fw/$option 2>/dev/null)
        for fw_version in "${fw_list[@]}";do
          if [[ `compare_version $fw_version $current_version` == 1 ]];then

            ### 固件存在判断
            fw=$(ls "./fw/$option/$fw_version/" | grep .bin)
            if [[ $fw != '' ]];then
              printf "run update command: flint -d $mellanox_dev -i ./fw/$option/$fw_version/$fw -y b"
              flint -d "$mellanox_dev" -i "./fw/$option/$fw_version/$fw" -y b

              if [ $? == 0 ];then
                echo "$mellanox_dev update succes"
              else
                echo "$mellanox_dev update failed"
              fi

            else
              echo "firware not exist, please check firware lib"
            fi
          fi
        done
    else
      echo "please install driver for $option"
    fi
  done
}

mellanox_downgrade


