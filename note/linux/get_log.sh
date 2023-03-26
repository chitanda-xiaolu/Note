#!/bin/bash

rm -rf /var/log/h3c/{tmp,var}  >/dev/null 2>&1
time=$(date +"%Y%m%d%H%M%S")
echo "解压：" 
newest_tar=$(ls -t /var/log/h3c/*tar.gz | head -1)
tar -xvf "$newest_tar" -C /var/log/h3c/ 

[ ! -d /var/log/h3c/tmp ] && echo "压缩包存在问题：$newest_tar" && exit 1

dmesg -L > /var/log/h3c/dmesg.log 
\cp /var/log/messages /var/log/h3c/tmp/messages
\cp /var/log/h3c/*.log /var/log/h3c/tmp

echo "打包："
cd /var/log/h3c/tmp/
tar -zvcf repoinstall-"$time".tar.gz *
cd -
mv /var/log/h3c/tmp/repoinstall-"$time".tar.gz .

rm -rf /var/log/h3c/{tmp,var}  >/dev/null 2>&1

# @pramam ip adress
# to check networck is ok
connected_check() {
  ping $1 -c 3 > /dev/null 2>&1
  if [ $? -ne 0 ];then
    echo "please check networck"
  else
    echo 1
  fi
}

 
mount_share_path() {
  #connect 100 Net disk
  if [[ `connected_check "172.16.0.100"` == 1 ]];then
    if [[ ! -d /repo_firmware_lib ]];then
      mkdir /repo_firmware_lib
    fi
    
    mount_statu=$(df | grep -i "//172.16.0.100/d/temp/zhoujingjing/log/")
    if [[ $mount_statu != "" ]];then
      echo 1
    else
      mount -t cifs -o vers=2.0,username=sit,password=h3c@123 //172.16.0.100/d/temp/zhoujingjing/log /mnt
      if [ $? = 0 ];then
        echo 1
      else
        echo "mount share path failed"
      fi
    fi
  fi
}
mount_share_path
serch_log=`ls | grep -i repoinstall`
cp -rf $serch_log /mnt