schedule_dict['mlxup']="hardware=mlxup_hardware version=mlxup_version update=mlxup_udpate"

mlxup_hardware() {
    mlx_info=$("$CURRENT_PATH"/mlxup --query -D "$CURRENT_PATH"/fw)
    echo "$mlx_info" >>"$LOGGER_FILE"
    echo "$mlx_info" | grep -iEq "Status: *Forced update required|Status: *Update required|Status: *Up to date" || repo_flag=1
}

mlxup_version() {
    mlx_info=$("$CURRENT_PATH"/mlxup --query -D "$CURRENT_PATH"/fw)
    echo "$mlx_info" | grep -iE "Status: *Forced update required|Status: *Update required|Status: *Up to date" -B6 | grep -iw "FW" | grep -v "Running" | awk '{print $2}' | sed 's/[0-9]*/xx/' | sort -u >>"$CURRENT_PATH"/version.txt
}

mlxup_udpate() {
    mlx_info=$("$CURRENT_PATH"/mlxup --query -D "$CURRENT_PATH"/fw)
    mapfile -t device_info < <(echo "$mlx_info" | grep -iE "Status: *Forced update required|Status: *Update required|Status: *Up to date" -B16 | grep -iE "^Device")
    
    logger_info "$CURRENT_PATH/mlxup -u -f -y -D $CURRENT_PATH/fw"
    update_result=$("$CURRENT_PATH"/mlxup -u -f -y -D "$CURRENT_PATH"/fw 2>&1)
    echo "$update_result" >>"$LOGGER_FILE"

    # 检查网卡是否升级成功
    for device in "${device_info[@]}"; do
        OKs=$(echo "$update_result" | grep -i -A2 "$device" | grep -c "OK")
        [ $OKs != 2 ] && repo_flag=1 && logger_error "$device 固件升级失败！"
    done

    # 配置
    for device in "${device_info[@]}"; do
        _bus=$(echo "$mlx_info" | grep -iE "$device" -A8 | grep -i "PCI Device Name" | awk '{print $NF}')
        # variable.sh中cfg=no时，不进行配置，同时恢复卡固件的默认配置
        if (echo "$mlx_info" | grep -iE "$device" -A8 | grep -i "Part Number" | awk '{print $NF}' | grep -iqE "^H3C") || [ "$cfg" = "no" ]; then
            logger_info "$CURRENT_PATH/mlxconfig -b $CURRENT_PATH/mlxconfig_host.db -d $_bus -y r"
            "$CURRENT_PATH"/mlxconfig -b "$CURRENT_PATH"/mlxconfig_host.db -d "$_bus" -y r >>"$LOGGER_FILE" 2>&1
        # 开启PXE功能以及Boot选项，外购卡来料默认不开启
        else
            config_array=(UEFI_HII_EN EXP_ROM_UEFI_x86_ENABLE)
            for config in "${config_array[@]}"; do
                find=$("$CURRENT_PATH"/mlxconfig -b "$CURRENT_PATH"/mlxconfig_host.db -d "$_bus" query | grep -i "$config" | awk -F "(" '{print $2}' | awk -F ")" '{print $1}')
                if [ -z "$find" ]; then
                    logger_err "$_bus的$config开关不存在"
                    continue
                fi
                if [ "$find" -ne 0 ]; then
                    logger_info "$_bus的$config开关已经开启"
                    continue
                fi
                if ! ("$CURRENT_PATH"/mlxconfig -b "$CURRENT_PATH"/mlxconfig_host.db -d "$_bus" -y set "$config"=1); then
                    repo_flag=1
                    logger_err "$_bus $config设置失败"
                fi
            done

        fi
    done

}

# 废弃
schedule_dict['mft']="hardware=_lib_func version=_lib_func:_ethtool update=_lib_func:mlx_update"
mlx_update() {
    # mst status
    # MST modules:
    # ------------
    #     MST PCI module is not loaded
    #     MST PCI configuration module loaded
    # MST devices:
    # ------------
    # /dev/mst/mt4119_pciconf0         - PCI configuration cycles access.
    #                                    domain:bus:dev.fn=0000:18:00.0 addr.reg=88 data.reg=92 cr_bar.gw_offset=-1
    #                                    Chip revision is: 00
    # /dev/mst/mt4119_pciconf1         - PCI configuration cycles access.
    #                                    domain:bus:dev.fn=0000:19:00.0 addr.reg=88 data.reg=92 cr_bar.gw_offset=-1
    #                                    Chip revision is: 00
    # 目前CX3的卡只有520F
    if "$LSPCI" -s "$line" | grep -i 'ConnectX-3' >/dev/null; then
        logger_info "ConnectX-3卡升级需要增加参数-use_image_ps"
        append="-use_image_ps"
    fi
    dev_id=$(mst status | grep -i -B1 "$line" | grep /dev/mst | awk '{print $1}' | head -n1)
    logger_info "flint -d $dev_id -i $CURRENT_PATH/$fw_file -y $append b"
    flint -d "$dev_id" -i "$CURRENT_PATH"/"$fw_file" -y $append b >>"$LOGGER_FILE" 2>&1
    __return_value=$?
    # MLX的卡如果已进行过一次升级且没有重启，那么再次升级将会失败（固件的自我保护机制）
    if [ "$__return_value" -ne 0 ]; then
        repo_flag=1
        logger_err "Flash update failed on device."
    else
        logger_info "Flash update completed on device."
        logger_info "The firmware image was already updated on flash, pending reset."
    fi

    # variable.sh中cfg=no时，不进行配置，同时恢复卡固件的默认配置
    if [ "$cfg" = "no" ]; then
        logger_info "mlxconfig -d $dev_id -y r"
        mlxconfig -d "$dev_id" -y r >>"$LOGGER_FILE" 2>&1
        return
    fi

    # mlxconfig -d /dev/mst/mt4119_pciconf0 q
    # UEFI_HII_EN                         True(1)
    # EXP_ROM_UEFI_x86_ENABLE             True(1)
    # 开启PXE功能以及Boot选项，外购卡来料默认不开启
    config_array=(UEFI_HII_EN EXP_ROM_UEFI_x86_ENABLE)
    for config in "${config_array[@]}"; do
        find=$(mlxconfig -d "$dev_id" query | grep -i "$config" | awk -F "(" '{print $2}' | awk -F ")" '{print $1}')
        if [ -z "$find" ]; then
            logger_err "$dev_id的$config开关不存在"
            continue
        fi
        if [ "$find" -ne 0 ]; then
            logger_info "$dev_id的$config开关已经开启"
            continue
        fi
        if ! (mlxconfig -d "$dev_id" -y set "$config"=1); then
            repo_flag=1
            logger_err "$dev_id $config设置失败"
        fi
    done

}


schedule_dict['nvmUpgrade']="hardware=bcm_hardware version=bcm_version update=bcm_update"

bcm_hardware() {
    nvmUpgrade_dir=$(find "$CURRENT_PATH" -mindepth 2 -type f -name "install.sh" -exec dirname {} \;)
    cd "$nvmUpgrade_dir" || exit
    bnxtnvm=$(find . -name "bnxtnvm_x86_64")
    devid_result=$("$bnxtnvm" devid)

    board_pn_list=$(find . -name "*.pkg" -exec basename {} \; | sed 's/.pkg//')
    logger_info "固件文件PN清单：\n$board_pn_list"

    mapfile -t dev_list < <(echo "$devid_result" | grep "^Device:" | awk '{print $NF}')
    repo_flag=1
    for dev in "${dev_list[@]}"; do
        device_get=$(echo "$devid_result" | grep -i "$dev" -A4 | grep "Subsys" | awk '{print $NF}' | tr "\n" " ")
        section=DEVICE_$(echo "$device_get" | awk '{print $1}')_$(echo "$device_get" | awk '{print $2}')
        board_pn=$(grep -i "$section" -A2 utils/nic_pkg.txt | grep "BOARD_PN" | cut -d= -f2)
        if [ -z "$board_pn" ] || ! echo "$board_pn_list" | grep -iwq "$board_pn"; then
            logger_info "设备不可升级，设备：$dev, PN：$board_pn，devid：$section"
            continue
        fi
        logger_info "设备可升级，设备：$dev, PN：$board_pn，devid：$section"
        repo_flag=0
    done


}

bcm_version() {
    nvmUpgrade_dir=$(find "$CURRENT_PATH" -mindepth 2 -type f -name "install.sh" -exec dirname {} \;)
    cd "$nvmUpgrade_dir" || exit
    bnxtnvm=$(find . -name "bnxtnvm_x86_64")
    devid_result=$("$bnxtnvm" devid)
    board_pn_list=$(find . -name "*.pkg" -exec basename {} \; | sed 's/.pkg//')

    mapfile -t dev_list < <(echo "$devid_result" | grep "^Device:" | awk '{print $NF}')
    for dev in "${dev_list[@]}"; do
        device_get=$(echo "$devid_result" | grep -i "$dev" -A4 | grep "Subsys" | awk '{print $NF}' | tr "\n" " ")
        section=DEVICE_$(echo "$device_get" | awk '{print $1}')_$(echo "$device_get" | awk '{print $2}')
        board_pn=$(grep -i "$section" -A2 utils/nic_pkg.txt | grep "BOARD_PN" | cut -d= -f2)
        [ -z "$board_pn" ] && continue
        echo "$board_pn_list" | grep -iwq "$board_pn" || continue
        version=$("$bnxtnvm" -dev="$dev" pkgver | grep "Package version on NVM" | awk '{print $NF}')
        logger_info "设备：$dev, 版本号：$version, PN：$board_pn，devid：$section"
        echo "$version" >>"$CURRENT_PATH"/version.txt
    done

}

bcm_update() {
    nvmUpgrade_dir=$(find "$CURRENT_PATH" -mindepth 2 -type f -name "install.sh" -exec dirname {} \;)
    cd "$nvmUpgrade_dir" || exit
    logger_info "./install.sh"
    ./install.sh >>"$LOGGER_FILE" 2>&1
    ret=$?
    if ! [[ $ret = 0 || $ret = 98 ]];then
        repo_flag=1
        logger_err "install.sh execute Fail!"
    fi
}


schedule_dict['eeupdate64e']="hardware=_lib_func version=eeupdate64e_version update=intel_update_eeupdate64e"


eeupdate64e_version() {
    eeupdate_data=$("$CURRENT_PATH"/eeupdate64e /ADAPTERINFO /PCIINFO /ALL)
    regular=$(echo 00.*00.*"${ids[*]}" | sed 's/ /|00.*00.*/g' | sed 's/,/.*/g')
    mapfile -t match_line < <(echo "$eeupdate_data" | grep -iE "$regular")
    for line in "${match_line[@]}"; do
        __bus=$(echo "$eeupdate_data" | grep -F "$line" | awk '{print $2}')
        [ -z "$lom" ] || _lom_check ":${__bus}:" || continue
        [ -z "$port_num" ] || _port_num_check ":${__bus}:" || continue
        echo "$eeupdate_data" | grep -F "$line" -A8 | awk '{$1=$1;print}' | grep -i "^NVM Version:" | cut -d: -f2 | awk '{print $1}'>>"$CURRENT_PATH"/version.txt
    done
}


intel_update_eeupdate64e() {
    eeupdate_data=$("$CURRENT_PATH"/eeupdate64e /ADAPTERINFO /PCIINFO /ALL)
    logger_aux "\n$CURRENT_PATH/eeupdate64e /ADAPTERINFO /PCIINFO /ALL\n$eeupdate_data"
    # 匹配案例
    # regular，形如00.*00.*8086.*1563.*8086.*0000|00.*00.*8086.*1563.*8086.*0002
    
    # NIC Bus Dev Fun Vendor-Device Sub Vendor-Device PCI rev     MAC
    # === === === === ============= ================= ======= ============
    #  2  4   00  01   8086-1521     193D-1015          01    C4346B3F01BB
    # 
    # 2:
    # EtrackID:            800009FA
    # Firmware Version:    DATE:2-5-12 REV:27.210
    # MAC Address:         C4-34-6B-3F-01-BB
    # NVM Version:         1.63
    # Serial Number:       c4346bffff3f01ba
    # 
    # NIC Bus Dev Fun Vendor-Device Sub Vendor-Device PCI rev     MAC 
    # === === === === ============= ================= ======= ============ 
    #  3  25   00  00   8086-1572     193D-1021          02    542BDE0B15EE 
    # 
    # 3: 
    # EtrackID:            8000BB92 
    # Firmware Version:    FW:8.5 API:1.15 
    # MAC Address:         54-2B-DE-0B-15-EE 
    # NVM Version:         8.50 MAP15.22 
    # Firmware Lockdown:   Unsupported 
    # Serial Number:       3154e3ffffd69738 
    regular=$(echo 00.*00.*"${ids[*]}" | sed 's/ /|00.*00.*/g' | sed 's/,/.*/g')
    mapfile -t match_line < <(echo "$eeupdate_data" | grep -iE "$regular")
    [ -z "${match_line[*]}" ] && repo_flag1=1
    if [ -d "$CURRENT_PATH"/fw ];then
        fw_file=$(_get_file "$CURRENT_PATH/fw" "bin$|txt$|eep$")
        flash_file=$(_get_file "$CURRENT_PATH"/fw "FLB$")
    fi
    for line in "${match_line[@]}"; do
        __bus=$(echo "$eeupdate_data" | grep -F "$line" | awk '{print $2}')
        [ -z "$lom" ] || _lom_check ":${__bus}:" || continue
        [ -z "$port_num" ] || _port_num_check ":${__bus}:" || continue
        __nic=$(echo "$eeupdate_data" | grep -F "$line" | awk '{print $1}')
        logger_info "$CURRENT_PATH/eeupdate64e /NIC=$__nic /D $fw_file"
        "$CURRENT_PATH"/eeupdate64e /NIC="$__nic" /D "$fw_file" >>"$LOGGER_FILE" 2>&1
        __return_value=$?
        if [ "$__return_value" -ne 0 ]; then
            repo_flag=1
            logger_err "eeupdate64e update $__bus Fail! eeupdate64e return value is $__return_value"
        fi
        [ -z "$flash_file" ] && continue
        __mac=$(echo "$eeupdate_data" | grep -F "$line" | awk '{print $NF}')
        logger_info "echo -e N\nY\n | $CURRENT_PATH/bootutil64e -MACADDR=$__mac -UP=COMBO -FILE=$flash_file"
        echo -e "N\nY\n" | "$CURRENT_PATH"/bootutil64e -MACADDR="$__mac" -UP=COMBO -FILE="$flash_file" 2>&1 | tee -a "$LOGGER_FILE" | grep -i "Flash update successful" > /dev/null
        __return_value=$?
        if [ "$__return_value" -ne 0 ]; then
            repo_flag=1
            logger_err "bootutil64e update $__bus Fail! bootutil64e return value is $__return_value"
        fi
    done
}


schedule_dict['nvmupdate64e']="hardware=nvmupdate64e_hardware version=nvmupdate64e_version update=intel_update_nvmupdate64e"

nvmupdate64e_hardware() {

    nvmupdate_dir=$(find "$CURRENT_PATH" -mindepth 2  -type f -name "nvmupdate64e" -exec dirname {} \;)
    cd "$nvmupdate_dir" || exit

    logger_info "./nvmupdate64e -i -l -c nvmupdate.cfg"

    ./nvmupdate64e -i -l -c nvmupdate.cfg | tee -a "$LOGGER_FILE" | awk '{$1=$1}{print}' | grep -iq "^ETrackId *:" || repo_flag=1

}

nvmupdate64e_version() {
    nvmupdate_dir=$(find "$CURRENT_PATH" -mindepth 2 -type f -name "nvmupdate64e" -exec dirname {} \;)
    cd "$nvmupdate_dir" || exit
    ./nvmupdate64e -i -l -c nvmupdate.cfg | awk '{$1=$1}{print}' | grep -i "^NVM Version *:" | awk '{print $NF}' | 
        cut -d\( -f2 | cut -d\) -f1 | sort -u >>"$CURRENT_PATH"/version.txt 

}


intel_update_nvmupdate64e(){
    nvmupdate_dir=$(find "$CURRENT_PATH" -mindepth 2 -type f -name "nvmupdate64e" -exec dirname {} \;)
    cd "$nvmupdate_dir" || exit
    data=$(./nvmupdate64e -i -l -c nvmupdate.cfg)
    if grep -iqE "^REPLACES" nvmupdate.cfg ;then
        etrack_id=$(echo "$data" | awk '{$1=$1}{print}' | grep -i "^ETrackId *:" | awk '{print $NF}' | sort -u | tr "\n" " ")
        sed -i "s/REPLACES:/REPLACES:$etrack_id/g" nvmupdate.cfg
    fi

    # 升级
    logger_info "echo -e \"a\nn\n\" | ./nvmupdate64e -f"
    update_result=$(echo -e "a\nn\n" | ./nvmupdate64e -f 2>&1)
    echo "$update_result" >>"$LOGGER_FILE"  

    mapfile -t nic_bus_list < <(echo "$data" | grep -iE '^\[.*:00:00]:' | cut -d: -f1-2 | tr -d '[' | sort -u)
    # 判断成功机制：通过bus定位到该卡，打印中包含successful算成功
    for __bus in "${nic_bus_list[@]}"; do
        local_flag=1
        logger_info "nvmupdate64e check $__bus"
        echo "$update_result" | grep -iE -A1 "$__bus" | grep -iv '^[0-9]*)' | grep -i 'successful' && local_flag=0
        [ "$local_flag" -eq 0 ] && continue
        echo "$update_result" | grep -iE "$__bus" | grep -i 'update successful' && local_flag=0
        [ "$local_flag" -eq 0 ] && continue
        logger_err "nvmupdate64e execute $__bus Fail!"
        repo_flag1=1
    done    
}


schedule_dict['arcconf']="hardware=_lib_func version=_lib_func:pmc_version update=_lib_func:pmc_update"


pmc_version() {
    slot_id=$("$LSPCI" -s "$line" -v | awk '{$1=$1;print}' | grep -i "^Physical Slot:" | awk '{print $NF}')
    controller_id=$("$CURRENT_PATH"/arcconf list | grep -iwF "Slot $slot_id" | cut -d: -f1 | awk '{print $NF}' | sed '/^\s*$/d')
    "$CURRENT_PATH"/arcconf getversion "$controller_id" | awk '{$1=$1;print}' | grep -i "^firmware" | 
        awk '{print $NF}' | awk -F"[" '{print $1}' >>"$CURRENT_PATH"/version.txt
}



pmc_update() {
    # ./arcconf list
    # Controllers found: 1
    # ----------------------------------------------------------------------
    # Controller information
    # ----------------------------------------------------------------------
    #    Controller ID             : Status, Slot, Mode, Name, SerialNumber, WWN
    # ----------------------------------------------------------------------
    #    Controller 1:             : Optimal, Slot 1, Mixed, UN HBA H460-B1, Unknown, 588DF9E37758A000
    # Command completed successfully.
    slot_id=$("$LSPCI" -s "$line" -v | awk '{$1=$1;print}' | grep -i "^Physical Slot:" | awk '{print $NF}')
    controller_id=$("$CURRENT_PATH"/arcconf list | grep -iwF "Slot $slot_id" | cut -d: -f1 | awk '{print $NF}' | sed '/^\s*$/d')
    subid=$("$SETPCI" -s "$line" 2c.l)
    seeprom_mapping_key="$(echo "$subid" | cut -c 5-)$(echo "$subid" | cut -c 1-4)"
    if [ -d "$CURRENT_PATH"/fw ];then
        fw_file=$(_get_file "$CURRENT_PATH/fw" "bin$" "seeprom.bin")
        fw_file1=$(_get_file "$CURRENT_PATH/fw" "${seeprom_mapping["$seeprom_mapping_key"]}")
    fi
    logger_info "固件文件升级：$fw_file"
    logger_info "$CURRENT_PATH/arcconf romupdate $controller_id $fw_file noprompt"
    if ! ("$CURRENT_PATH"/arcconf romupdate "$controller_id" "$fw_file" noprompt >>"$LOGGER_FILE" 2>&1); then
        repo_flag1=1
        logger_err "arcconf execute Fail!"
    fi

    if [[ "$SCENE" =~ 'yongfu' ]] ; then
        logger_info "用服不刷eeprom"
    else
        logger_info "eeprom文件升级：$fw_file1"
        logger_info "$CURRENT_PATH/ssflash --ctrl slot=$slot_id --flash-nvram=$fw_file1 --preserve"
        if ! ("$CURRENT_PATH"/ssflash --ctrl "slot=$slot_id" --flash-nvram="$fw_file1" --preserve >>"$LOGGER_FILE" 2>&1); then
            repo_flag1=1
            logger_err "ssflash execute Fail!"
        fi
    fi

}


schedule_dict['storcli64']="hardware=_lib_func version=lsi_version update=lsi_update"


lsi_version() {
    storcli64_info=$("$CURRENT_PATH"/storcli64 /call show)
    mapfile -t match_line < <(echo "$storcli64_info" | grep -i "^Controller *=")

    for line in "${match_line[@]}"; do
        data=$(echo "$storcli64_info" | grep -F "$line" -A24)
        id_data=$(echo "$data" | awk '{$1=$1}{print}' | grep -iE "^Device Id|^Vendor Id|^SubVendor Id|^SubDevice Id" | sed 's/0x//')
        vendorID=$(echo "$id_data" | grep -i "^Vendor Id *=" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        deviceID=$(echo "$id_data" | grep -i "^Device Id *=" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_vendorID=$(echo "$id_data" | grep -i "^SubVendor Id *=" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_deviceID=$(echo "$id_data" | grep -i "^SubDevice Id *=" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')

        if echo "$vendorID $deviceID $sub_vendorID $sub_deviceID" | grep -iE "$pci_ids_str" > /dev/null; then
            logger_info "id匹配成功！id：$vendorID $deviceID $sub_vendorID $sub_deviceID"

            # 9300/9400等的pkg版本为00.00.00.00，这时候只能取它的FW版本，其它的LSI卡取pkg版本
            pkg_version=$(echo "$data" | grep -i "^FW Package Build *=" | awk '{print $NF}')
            if echo "$pkg_version" | grep -i '^00.00' > /dev/null; then
                echo "$data" | grep -i "^FW Version *=" | awk '{print $NF}' >>"$CURRENT_PATH"/version.txt
            else
                echo "$pkg_version" >>"$CURRENT_PATH"/version.txt
            fi
        else
            logger_info "id匹配失败，仅记录！id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
        fi 
    done

}


lsi_update() {
    # cmd: ./storcli64 /call show | grep -i "Product Name = SAS9311-8i" -A20 -B6
    # ./storcli64 show
    # CLI Version = 007.1705.0000.0000 Mar 31, 2021
    # Operating system = Linux 4.18.0-193.el8.x86_64
    # Controller = 3
    # Status = Success
    # Description = None
    # 
    # Product Name = SAS9311-8i
    # Serial Number = SP93420853
    # SAS Address =  500605b00f417c50
    # PCI Address = 00:ad:00:00
    # System Time = 06/29/2022 01:52:50
    # FW Package Build = 00.00.00.00
    # FW Version = 16.00.16.00
    # BIOS Version = 08.37.00.00_18.00.00.00
    # NVDATA Version = 14.01.00.12
    # Driver Name = mpt3sas
    # Driver Version = 32.100.00.00
    # Bus Number = 173
    # Device Number = 0
    # Function Number = 0
    # Domain ID = 0
    # Vendor Id = 0x1000
    # Device Id = 0x97
    # SubVendor Id = 0x1000
    # SubDevice Id = 0x3090
    # Board Name = SAS9311-8i
    # Board Assembly = H3-25461-02H
    storcli64_info=$("$CURRENT_PATH"/storcli64 /call show)
    logger_aux "$CURRENT_PATH/storcli64 /call show\n$storcli64_info"
    mapfile -t match_line < <(echo "$storcli64_info" | grep -i "^Controller *=")
    if [ -d "$CURRENT_PATH"/fw ];then
        fw_file=$(_get_file "$CURRENT_PATH/fw" "bin$|rom$")
        bios_rom=$(_get_file "$CURRENT_PATH/fw/bios_file" "rom$")
        efi_bios_rom=$(_get_file "$CURRENT_PATH/fw/efi_bios_file" "rom$")
    fi
    repo_flag=1
    for line in "${match_line[@]}"; do
        data=$(echo "$storcli64_info" | grep -F "$line" -A24)
        id_data=$(echo "$data" | awk '{$1=$1}{print}' | grep -iE "^Device Id|^Vendor Id|^SubVendor Id|^SubDevice Id" | sed 's/0x//')
        vendorID=$(echo "$id_data" | grep -i "^Vendor Id *=" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        deviceID=$(echo "$id_data" | grep -i "^Device Id *=" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_vendorID=$(echo "$id_data" | grep -i "^SubVendor Id *=" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_deviceID=$(echo "$id_data" | grep -i "^SubDevice Id *=" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')

        if echo "$vendorID $deviceID $sub_vendorID $sub_deviceID" | grep -iE "$pci_ids_str" > /dev/null; then
            logger_info "id匹配成功！id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
            repo_flag=0
            
            controller_id=$(echo "$data" | grep -i '^Controller *=' | awk '{print $NF}')
            logger_info "$CURRENT_PATH/storcli64 /c$controller_id download file=$fw_file Noverchk"
            if ! ("$CURRENT_PATH"/storcli64 /c"$controller_id" download file="$fw_file" Noverchk >>"$LOGGER_FILE" 2>&1); then
                repo_flag1=1
                logger_err "storcli64 execute Fail!"
            fi
            if [ -n "$bios_rom" ]; then
                logger_info "$CURRENT_PATH/storcli64 /c$controller_id download bios file=$bios_rom"
                if ! ("$CURRENT_PATH"/storcli64 /c"$controller_id" download bios file="$bios_rom" >>"$LOGGER_FILE" 2>&1); then
                    repo_flag1=1
                fi
            fi
            if [ -n "$efi_bios_rom" ]; then
                logger_info "$CURRENT_PATH/storcli64 /c$controller_id download efibios file=$efi_bios_rom"
                if ! ("$CURRENT_PATH"/storcli64 /c"$controller_id" download efibios file="$efi_bios_rom" >>"$LOGGER_FILE" 2>&1); then
                    repo_flag1=1
                fi
            fi

        else
            logger_info "id匹配失败，仅记录！id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
        fi 
        
    done
}


# 支持并行升级，单卡升级约1分钟
schedule_dict['elxocm']="hardware=_lib_func version=lpe_version update=lpe_update"


lpe_version() {
    mapfile -t port_wwn_list < <(hbacmd ListHBAs | grep -i "Port WWN" | awk '{print $4}' | sed '/^\s*$/d') 
    for port_wwn in "${port_wwn_list[@]}"; do 
        data=$(hbacmd HbaAttributes "$port_wwn")
        id_data=$(echo "$data" | awk '{$1=$1}{print}' | grep -iE "^Vendor Spec ID|^Device ID|^Sub Vendor ID|^Sub Device ID")
        # 只查询第一个端口
        echo "$data" | grep -i "^PCI Func Number *: *0" >/dev/null || continue
        vendorID=$(echo "$id_data" | grep -i "^Vendor Spec ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        deviceID=$(echo "$id_data" | grep -i "^Device ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_vendorID=$(echo "$id_data" | grep -i "^Sub Vendor ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_deviceID=$(echo "$id_data" | grep -i "^Sub Device ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')

        if echo "$vendorID $deviceID $sub_vendorID $sub_deviceID" | grep -iE "$pci_ids_str" > /dev/null; then
            logger_info "id匹配成功！port_wwn=$port_wwn, id=$vendorID $deviceID $sub_vendorID $sub_deviceID"
            echo "$data" | grep -i '^FW Version' | awk '{print $NF}' >>"$CURRENT_PATH"/version.txt 
        else
            logger_info "id匹配失败，仅记录！port_wwn=$port_wwn, id=$vendorID $deviceID $sub_vendorID $sub_deviceID"
        fi 
    done 
} 


lpe_update() { 
    # hbacmd HbaAttributes 10:00:00:10:9b:1c:3a:7b
    # 
    # HBA Attributes for 10:00:00:10:9b:1c:3a:7b
    # 
    # Host Name                     : localhost.localdomain
    # Manufacturer                  : Emulex Corporation
    # Serial Number                 : FC72162211
    # Model                         : LPe31002-M6
    # Model Desc                    : Emulex LightPulse LPe32000 Fibre Channel Adapter
    # Node WWN                      : 20 00 00 10 9b 1c 3a 7b
    # Node Symname                  :
    # HW Version                    : 0000000c 00000001 00000000
    # FW Version                    : 11.2.156.27
    # Vendor Spec ID                : 10DF
    # Number of Ports               : 1
    # Driver Name                   : lpfc
    # Driver Version                : 12.6.0.2; HBAAPI(I) v2.3.d, 07-12-10
    # Device ID                     : E300
    # HBA Type                      : LPe31002-M6
    # Operational FW                : 11.2.156.27
    # IEEE Address                  : 00 10 9b 1c 3a 7b
    # Boot Code                     : Enabled
    # Boot Version                  : 14.0.505.11
    # Board Temperature             : Normal
    # Function Type                 : FC
    # Sub Device ID                 : E310
    # PCI Bus Number                : 89
    # PCI Func Number               : 1
    # Sub Vendor ID                 : 10DF
    # IPL Filename                  : H62LEXA1
    # Service Processor FW Name     : 11.2.156.27
    # ULP FW Name                   : 11.2.156.27
    # FC Universal BIOS Version     : 14.0.505.11
    # FC x86 BIOS Version           : 14.0.505.10
    # FC EFI BIOS Version           : 14.0.505.6
    # FC FCODE Version              : 14.0.490.0
    # Flash Firmware Version        : 14.0.505.11
    # Secure Firmware               : Enabled
    repo_flag=1 
    mapfile -t port_wwn_list < <(hbacmd ListHBAs | grep -i "Port WWN" | awk '{print $4}' | sed '/^\s*$/d') 
    if [ -d "$CURRENT_PATH"/fw ];then
        fw_file=$(_get_file "$CURRENT_PATH/fw" "grp$")
    fi
    for port_wwn in "${port_wwn_list[@]}"; do 
        data=$(hbacmd HbaAttributes "$port_wwn")
        logger_aux "hbacmd HbaAttributes $port_wwn\n$data"
        id_data=$(echo "$data" | awk '{$1=$1}{print}' | grep -iE "^Vendor Spec ID|^Device ID|^Sub Vendor ID|^Sub Device ID")
        # 只查询第一个端口
        echo "$data" | grep -i "^PCI Func Number *: *0" >/dev/null || continue
        vendorID=$(echo "$id_data" | grep -i "^Vendor Spec ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        deviceID=$(echo "$id_data" | grep -i "^Device ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_vendorID=$(echo "$id_data" | grep -i "^Sub Vendor ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_deviceID=$(echo "$id_data" | grep -i "^Sub Device ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')

        if echo "$vendorID $deviceID $sub_vendorID $sub_deviceID" | grep -iE "$pci_ids_str" > /dev/null; then
            repo_flag=0
            logger_info "id匹配成功！port_wwn：$port_wwn, id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
            logger_info "hbacmd Download $port_wwn $fw_file" 
            if ! (hbacmd Download "$port_wwn" "$fw_file" 2>&1 | tee -a "$LOGGER_FILE" | 
                grep -iE 'Download Complete.|The new firmware is activated. Some features require an optional reboot.' >/dev/null); then
                repo_flag1=1 
                logger_err "hbacmd execute $port_wwn Fail!" 
            fi
        else
            logger_info "id匹配失败，仅记录！port_wwn：$port_wwn, id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
        fi 
    done 

}


# 支持并行升级，单卡升级约1分钟
schedule_dict['QConCLI']="hardware=_lib_func version=qle_version update=qle_update"


qle_version() {
    qaucli_info=$(qaucli -i)
    mapfile -t match_line < <(echo "$qaucli_info" | grep -i "^HBA Instance *:")

    for line in "${match_line[@]}"; do
        instance=$(echo "$line" | awk '{print $NF}')
        data=$(echo "$qaucli_info" | grep -F "$line" -A50)
        echo "$data" | grep -i "^HBA Port *: *1" >/dev/null || continue
        id_data=$(echo "$data" | awk '{$1=$1}{print}' | grep -iE "^PCI Device ID|^Subsystem Device ID|^Subsystem Vendor ID"  | sed 's/0x//')
        vendorID=$(echo "$id_data" | grep -i "^Subsystem Vendor ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        deviceID=$(echo "$id_data" | grep -i "^PCI Device ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_vendorID=$(echo "$id_data" | grep -i "^Subsystem Vendor ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_deviceID=$(echo "$id_data" | grep -i "^Subsystem Device ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')

        if echo "$vendorID $deviceID $sub_vendorID $sub_deviceID" | grep -iE "$pci_ids_str" > /dev/null; then
            logger_info "id匹配成功！instance：$instance, id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
            echo "$data" | grep -i "Flash Firmware Version" | awk '{print $NF}' >>"$CURRENT_PATH"/version.txt
        else
            logger_info "id匹配失败，仅记录！instance：$instance, id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
        fi 
    done
}


qle_update() {
    # Host Name                      : localhost.localdomain
    # Host NQN                       :
    # HBA Instance                   : 0
    # HBA Model                      : QLE2690
    # HBA Description                : QLogic QLE2690 Single Port 16Gb FC to PCIe Gen3 x8 Adapter
    # HBA ID                         : 0-QLE2690
    # HBA Alias                      :
    # HBA Port                       : 1
    # Port Alias                     :
    # Node Name                      : 20-00-00-24-FF-14-12-64
    # Port Name                      : 21-00-00-24-FF-14-12-64
    # Port ID                        : 00-00-00
    # Principal Fabric WWN           : Not connected
    # Adjacent Fabric WWN            : Not connected
    # Serial Number                  : RFD1703R00718
    # Driver Version                 : 10.01.00.21.08.2-k
    # BIOS Version                   : 3.62
    # Running Firmware Version       : 9.07.00 (d0d5)
    # Running MPI Firmware Version   : 3.02.01
    # Running PEP Firmware Version   : 2.01.23
    # Flash BIOS Version             : 3.62
    # Flash FCode Version            : 4.11
    # Flash EFI Version              : 7.17
    # Flash Firmware Version         : 9.07.00
    # Flash MPI Firmware Version     : 255.255.255
    # Flash PEP Firmware Version     : 255.255.255
    # Actual Connection Mode         : Unknown
    # Actual Data Rate               : Unknown
    # Supported Speed(s)             : 4 8 16 Gbps
    # Chip Model Name                : ISP2722-based 16/32Gb Fibre Channel to PCIe Adapter
    # Chip Revision                  : 0x1(A0)
    # PortType (Topology)            : Unidentified
    # Target Count                   : 0
    # PCI Bus Number                 : 173
    # PCI Device Number              : 0
    # PCI Function Number            : 0
    # PCI Device ID                  : 0x2261
    # Subsystem Device ID            : 0x029b
    # Subsystem Vendor ID            : 0x1077
    repo_flag=1
    qaucli_info=$(qaucli -i)
    logger_aux "qaucli -i\n$qaucli_info"
    mapfile -t match_line < <(echo "$qaucli_info" | grep -i "^HBA Instance *:")
    if [ -d "$CURRENT_PATH"/fw ];then
        fw_file=$(_get_file "$CURRENT_PATH/fw" "bin$")
    fi
    for line in "${match_line[@]}"; do
        instance=$(echo "$line" | awk '{print $NF}')
        data=$(echo "$qaucli_info" | grep -F "$line" -A50)
        echo "$data" | grep -i "^HBA Port *: *1" >/dev/null || continue
        id_data=$(echo "$data" | awk '{$1=$1}{print}' | grep -iE "^PCI Device ID|^Subsystem Device ID|^Subsystem Vendor ID"  | sed 's/0x//')
        vendorID=$(echo "$id_data" | grep -i "^Subsystem Vendor ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        deviceID=$(echo "$id_data" | grep -i "^PCI Device ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_vendorID=$(echo "$id_data" | grep -i "^Subsystem Vendor ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_deviceID=$(echo "$id_data" | grep -i "^Subsystem Device ID *:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')

        if echo "$vendorID $deviceID $sub_vendorID $sub_deviceID" | grep -iE "$pci_ids_str" > /dev/null; then
            repo_flag=0
            logger_info "id匹配成功！instance：$instance, id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
            logger_info "qaucli -b $instance -rg all $fw_file"
            if ! (qaucli -b "$instance" -rg all "$fw_file" 2>&1 | tee -a "$LOGGER_FILE" | grep -i 'Flash update complete.' >/dev/null); then
                repo_flag1=1
                logger_err "qaucli execute Fail!"
            fi
        else
            logger_info "id匹配失败，仅记录！instance：$instance, id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
        fi 
    done
}


# 暂时不会有多卡的配置，不考虑并行方案。每张卡升级大概1.5分钟
schedule_dict['mnv_cli']="hardware=_lib_func version=mnv_cli_version update=mnv_cli_update"


mnv_cli_version() {
    cd "$CURRENT_PATH" || exit
    Controllers=$("$CURRENT_PATH"/mnv_cli adapter --list | grep -i "NVMe Controllers:" | awk '{print $NF}')
    for num in $(seq "$Controllers")
    do
        data=$("$CURRENT_PATH"/mnv_cli "$((num-1))" info -o hba  | sed 's/0x//')
        echo "$data" | grep -i "^Bus Device Fun:.*00$" >/dev/null || continue
        vendorID=$(echo "$data" | grep -i "^VID:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        deviceID=$(echo "$data" | grep -i "^DID:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_vendorID=$(echo "$data" | grep -i "^SVID:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_deviceID=$(echo "$data" | grep -i "^SDID:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        
        if echo "$vendorID $deviceID $sub_vendorID $sub_deviceID" | grep -iE "$pci_ids_str" > /dev/null; then
            logger_info "id匹配成功！id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
            # 8.80(8.50)，取括号内部的版本
            echo "$data" | awk '{$1=$1}{print}' | grep -i "^Firmware Version:" | awk '{print $NF}' >>"$CURRENT_PATH"/version.txt 
        else
            logger_info "id匹配失败，仅记录！id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
        fi
    done
}


mnv_cli_update() {
    # ./mnv_cli 0 info -o hba
    # NVMe Controller ID                   0
    # Bus Device Fun:                      45:00.00
    # Device:                              /dev/nvme0
    # SUBNQN:                              00221730058H        SSSTC CA5-8D256                         16
    # Firmware Version:                    1.0.0.1051
    # VID:                                 0x1b4b
    # SVID:                                0x1b4b
    # DID:                                 0x2241
    # SDID:                                0x2241
    # RevisionID:                          B0B
    # Port Count:                          2
    # Max PD of Per VD:                    2
    # Max VD:                              2
    # Max PD:                              2
    # Max NS of Per VD:                    1
    # Max NS:                              2
    # Host ID:                             0
    # Supported RAID Mode:                 RAID0 RAID1 JBOD
    # Cache:                               On
    # Supported BGA Features:              Initialization Rebuild MediaPatrol
    # Support Stripe Size:                 128KB 256KB 512KB
    # Supported Features:                  Import RAID Namespace Dump
    # Root Complex:                        0
    # Link width:                        4x
    # PCIe speed:                        8Gb/s
    # Root Complex:                        1
    # Link width:                        4x
    # PCIe speed:                        8Gb/s
    # End Point:                           0
    # Link width:                        4x
    # PCIe speed:                        8Gb/s
    
    cd "$CURRENT_PATH" || exit
    repo_flag1=1
    Controllers=$("$CURRENT_PATH"/mnv_cli adapter --list | grep -i "NVMe Controllers:" | awk '{print $NF}')
    if [ -d "$CURRENT_PATH"/fw ];then
        fw_file=$(_get_file "$CURRENT_PATH/fw" "bin$")
    fi
    for num in $(seq "$Controllers")
    do
        data=$("$CURRENT_PATH"/mnv_cli "$((num-1))" info -o hba  | sed 's/0x//')
        logger_info "$CURRENT_PATH/mnv_cli "$((num-1))" info -o hba\n$data"
        echo "$data" | grep -i "^Bus Device Fun:.*00$" >/dev/null || continue
        vendorID=$(echo "$data" | grep -i "^VID:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        deviceID=$(echo "$data" | grep -i "^DID:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_vendorID=$(echo "$data" | grep -i "^SVID:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        sub_deviceID=$(echo "$data" | grep -i "^SDID:" | awk '{printf("%04s\n",$NF)}' | sed 's/ /0/g')
        
        if echo "$vendorID $deviceID $sub_vendorID $sub_deviceID" | grep -iE "$pci_ids_str" > /dev/null; then
            repo_flag1=0
            logger_info "id匹配成功！id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
            logger_info "$CURRENT_PATH/mnv_cli $((num-1)) flash -o hba -t raw -f $fw_file"
            if ! ("$CURRENT_PATH"/mnv_cli "$((num-1))" flash -o hba -t raw -f "$fw_file" 2>&1 | tee -a "$LOGGER_FILE" | grep -i 'Flash NVMe Controller firmware success' >/dev/null); then
                repo_flag1=1
                logger_err "mnv_cli execute Fail!"
            fi
        else
            logger_info "id匹配失败，仅记录！id：$vendorID $deviceID $sub_vendorID $sub_deviceID"
        fi
    
    done
}


# 支持并行
schedule_dict['sfc']="hardware=_lib_func version=_lib_func:_ethtool update=_lib_func:sfc_update"


sfc_update() {
    # Solarflare firmware update utility [v8.2.2]
    # Copyright 2002-2020 Xilinx, Inc.
    # Loading firmware images from /usr/share/sfutils/sfupdate_images
    # 
    # ens2f0np0 - MAC: 00-0F-53-84-53-50
    #     Firmware version:   v8.0.1
    #     Controller type:    Solarflare SFC9250 family
    #     Controller version: v8.0.0.1015
    #     Boot ROM version:   v5.2.2.1006
    #     MUM type:           Micro-controller
    #     MUM version:        v2.1.1.1028
    #     UEFI ROM version:   v2.9.6.3
    #     Bundle type:        X2522 25G
    #     Bundle version:     v8.0.1.1002
    # 
    # The Bundle firmware is up to date
    # 
    # ens2f1np1 - MAC: 00-0F-53-84-53-51
    #     Firmware version:   v8.0.1
    #     Controller type:    Solarflare SFC9250 family
    #     Controller version: v8.0.0.1015
    #     Boot ROM version:   v5.2.2.1006
    #     MUM type:           Micro-controller
    #     MUM version:        v2.1.1.1028
    #     UEFI ROM version:   v2.9.6.3
    #     Bundle type:        X2522 25G
    #     Bundle version:     v8.0.1.1002
    # 
    # The Bundle firmware is up to date
    __device=$(find /sys/bus/pci/devices/"$line"/net -maxdepth 1 -mindepth 1 -printf "%f\n" 2>/dev/null | head -n1 | awk '{print $1}')
    logger_info "sfupdate --adapter=$__device --write --yes --force"
    if ! (sfupdate --adapter="$__device" --write --yes --force >>"$LOGGER_FILE" 2>&1); then
        repo_flag=1
        logger_err "sfupdate execute Fail!"
    fi
}


# 工具是一把升级的，内部是串行的（RP1000）
schedule_dict['raptor']="hardware=_lib_func version=_lib_func:_ethtool update=raptor_update"


raptor_update() {
    # ./raptor_pci_utils -F prd_flash_rp1000_20006_for_H3C.img -M 2 -A 2
    # 
    # Raptor PCI Utils tool is started.
    # We will download 2 in 2 cards depends on the configuration.
    # 
    # Start to download No.0 adaptor card [ 97:00.0 ]:
    # Old: MAC Address0 is: 0x3009f92009e0
    #      MAC Address1 is: 0x3009f92009e1
    #      SN is: 0x020182011808070683
    # Start to download image to adaptor ...... complete 100%
    # New: MAC Address0 is: 0x3009f92009e0
    #      MAC Address1 is: 0x3009f92009e1
    #      SN is: 0x020182011808070683
    # 
    # Start to download No.1 adaptor card [ 15:00.0 ]:
    # Old: MAC Address0 is: 0x3009f92019aa
    #      MAC Address1 is: 0x3009f92019ab
    #      SN is: 0x020182011812070594
    # Start to download image to adaptor ...... complete 100%
    # New: MAC Address0 is: 0x3009f92019aa
    #      MAC Address1 is: 0x3009f92019ab
    #      SN is: 0x020182011812070594
    # 
    # 
    # [ ^_^ ] Raptor PCI Utils upgrading is succeeded! 2 cards are upgraded!!
    card_num=0
    if [ -d "$CURRENT_PATH"/fw ];then
        fw_file=$(_get_file "$CURRENT_PATH/fw" "img$")
    fi
    for id in "${ids[@]}"; do
        mapfile -t __id_list < <($LSPCI -Dnn 2>/dev/null | grep -i "${id:0:4}:${id:5:4}" | awk '{print $1}' | cut -d. -f1 | sort -u | sed '/^\s*$/d')
        for bus_id in "${__id_list[@]}"; do
            line=${bus_id}.0
            subid=$($SETPCI -s "$line" 2c.l | tr '[:lower:]' '[:upper:]')
            if [ "$subid" = "${id:15:4}${id:10:4}" ]; then
                (( card_num++ ))
            fi
        done
    done
    # 如果卡个数为零，工具命令返回不为零
    # 如果卡个数与工具查询到的卡数不同，工具命令返回不为零
    logger_info "$CURRENT_PATH/raptor_pci_utils -F $fw_file -M 2 -A $card_num"
    if ! ("$CURRENT_PATH"/raptor_pci_utils -F "$fw_file" -M 2 -A "$card_num" >>"$LOGGER_FILE" 2>&1); then
        repo_flag=1
        logger_err "raptor_pci_utils execute Fail!"
    fi
}


# 不支持并行升级，并行时首张卡成功，后续卡都失败：The MBI upgrade has failed !!! 每张卡升级大概2分钟（530F卡、Cavium卡）
schedule_dict['lnxfwnx2']="hardware=_lib_func version=_lib_func:lnxfwnx2_version update=_lib_func:lnxfwnx2_update"


lnxfwnx2_version() {
    __device=$(find /sys/bus/pci/devices/"$line"/net -maxdepth 1 -mindepth 1 -printf "%f\n" 2>/dev/null | head -n1 | awk '{print $1}')
    mac=$(tr -d ':' < /sys/class/net/"$__device"/address | tr '[:lower:]' '[:upper:]')
    "$CURRENT_PATH"/lnxfwnx2 "$mac" vpd -show | grep -i '^V0' | awk '{print $NF}' >> "$CURRENT_PATH"/version.txt
}


lnxfwnx2_update() {
    #  ./lnxfwnx2
    # ***********************************************************************************************
    # QLogic Firmware Upgrade Utility for Linux v2.10.78
    # ***********************************************************************************************
    # 
    # C  Brd      MAC      Drv                     Name                                        MFW
    # -  ---- ------------ --- ----------------------------------------------------------- ----------
    # 0* 168E 000717273708 Yes NetXtreme II BCM57810 10 Gigabit Ethernet rev 10 (ens6f0)   7.15.23
    # 1  168E 88DF9E32D1D2 Yes NetXtreme II BCM57810 10 Gigabit Ethernet rev 10 (ens11f0)  7.13.0
    # 2  168E 000717273712 Yes NetXtreme II BCM57810 10 Gigabit Ethernet rev 10 (ens6f1)   7.15.23
    # 3  168E 88DF9E32D1D4 Yes NetXtreme II BCM57810 10 Gigabit Ethernet rev 10 (ens11f1)  7.13.0
    # 4  168E 3897D6E25405 Yes NetXtreme II BCM57810 10 Gigabit Ethernet rev 10 (ens2f0)   7.15.23
    # 5  168E 3897D6E25406 Yes NetXtreme II BCM57810 10 Gigabit Ethernet rev 10 (ens2f1)   7.15.23

    __device=$(find /sys/bus/pci/devices/"$line"/net -maxdepth 1 -mindepth 1 -printf "%f\n" 2>/dev/null | head -n1 | awk '{print $1}')
    mac=$(tr -d ':' < /sys/class/net/"$__device"/address | tr '[:lower:]' '[:upper:]')
    if [ -d "$CURRENT_PATH"/fw ];then
        fw_file=$(_get_file "$CURRENT_PATH/fw" "bin$")
    fi
    logger_info "$CURRENT_PATH/lnxfwnx2 $mac upgrade -f -mbi $fw_file"
    if ! ("$CURRENT_PATH"/lnxfwnx2 "$mac" upgrade -f -mbi "$fw_file" | tee -a "$LOGGER_FILE" | grep -i "CRC check passed successfully" > /dev/null); then
        repo_flag=1
    fi
    # 自研网卡在variable中将cfg置为no
    [ "$cfg" != no ] && return

    to_be_version=$(grep -i '<version value=' "$CURRENT_PATH/manager.xml" | cut -d\" -f2 | cut -d\' -f2)
    logger_info "$CURRENT_PATH/lnxfwnx2 $mac cfg -noreset -vpdv0 $to_be_version"
    "$CURRENT_PATH"/lnxfwnx2 "$mac" cfg -noreset -vpdv0 "$to_be_version" >> "$LOGGER_FILE" 

}
