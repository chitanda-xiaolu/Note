### 1.0版本说明
mellanox_fw_downgrade支持的固件降级方式为：flint -d "\$mellanox\_dev" -i $fw -y b
若硬件不支持该方式刷固件，则无法正常使用mellanox_fw_downgrade


### 使用方法
在fw目录下以卡名(卡名使用repo_base_info.xlsx中的repo名称)新建文件夹
```sh
  lkf9206@llyj0093 MINGW64 ~/Desktop/组件包降级工具/mellanox_fw_downgrade/fw
  $ ls
  IB-MCX354A-FCBT/     IB-MCX653105A-HDAT/   NIC-MCX515A-CCAT/
  IB-MCX453A-FCAT/     IB-MCX653106A-ECAT/   NIC-MCX516A-CCAT/
  IB-MCX555A-ECAT/     NIC-520F-B2/          NIC-MCX542B-ACAN/
  IB-MCX556A-ECAT/     NIC-MCX4121A-B-25Gb/  NIC-MCX562A-3S/
  IB-MCX653105A-ECAT/  NIC-MCX512A-ACAT/     NIC-MCX623106AN-CDAT/

```
卡名文件夹下，以固件版本号命名存放固件的文件夹，将固件拖至对应的文件夹内

```sh
  lkf9206@llyj0093 MINGW64 ~/Desktop/组件包降级工具/mellanox_fw_downgrade/fw
  $ ll NIC-MCX512A-ACAT
  total 0
  drwxr-xr-x 1 lkf9206 1049089 0 Jul 19 11:04 16.23.1020/
  drwxr-xr-x 1 lkf9206 1049089 0 Jul 19 11:04 16.25.1020/
  drwxr-xr-x 1 lkf9206 1049089 0 Jul 19 11:03 16.27.2008/
  drwxr-xr-x 1 lkf9206 1049089 0 Jul 19 11:03 16.30.1004/
```
复权后执行mellanox_fw_downgrade.sh，选择对应卡的ID以空格为分隔符进行固件的降级
```sh
  [root@localhost mellanox_fw_downgrade]# bash mellanox_fw_downgrade.sh
  =====================Update list:=========================
  ID:1  IB-MCX653105A-ECAT  18  /dev/mst/mt4123_pciconf0
  ID:2  NIC-MCX516A-CCAT  3b  /dev/mst/mt4119_pciconf0
  ID:3  IB-MCX555A-ECAT  86  /dev/mst/mt4119_pciconf1
  ID:4  NIC-MCX4121A-B-25Gb  af  /dev/mst/mt4117_pciconf0
  ID:5  NIC-MCX512A-ACAT  b0  /dev/mst/mt4119_pciconf2
  ==========================================================
  Please input option ID for update: 1 2 3 4 5
```
