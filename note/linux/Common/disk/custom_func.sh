nvme_hardware() {
    logger_info "nvme list | grep -iaE $HdModel"
    nvme list | grep -iaE "$HdModel" >>"$LOGGER_FILE" || repo_flag=1
}


nvme_version() {
    nvme list | grep -iaE "$HdModel" | awk '{print $NF}' >"$CURRENT_PATH"/version.txt
    if [ -f "$CURRENT_PATH/manager.xml" ]; then
        xml_version=$(grep -i '<version value=' "$CURRENT_PATH/manager.xml" | cut -d\" -f2 | cut -d\' -f2)
        xml_width=$(echo "$xml_version" | wc -L)
        mapfile -t version_txt_str < <(awk '{$1=$1;print}' version.txt | sort -u)
        cat /dev/null > version.txt

        for _disk in "${version_txt_str[@]}"; do
            _len=$(echo "$_disk" | wc -L)
            if [ "$xml_width" -gt "$_len" ]; then
                offset_width=$((xml_width-_len))
                echo "$(echo "$xml_version" | cut -c -$offset_width)$_disk" >>"$CURRENT_PATH"/version.txt
            else 
                echo "$_disk" >>"$CURRENT_PATH"/version.txt
            fi
        done
    fi
}


nvme_update() {
    # Node             SN                   Model                                    Namespace Usage                      Format           FW Rev
    # ---------------- -------------------- ---------------------------------------- --------- -------------------------- ---------------- --------
    # /dev/nvme0n1     10030038421911001L   PU7T6T0166500                            1           7.68  TB /   7.68  TB    512   B +  0 B   6025
    # /dev/nvme3n1     FL184200062          P5510DS0192T00                           1           1.92  TB /   1.92  TB    512   B +  0 B   224005A0
    mapfile -t nvme_list < <(nvme list | grep -iaE "$HdModel" | awk '{print $1}' | sed '/^\s*$/d')
    [ -z "${nvme_list[*]}" ] && repo_flag1=1
    for Index in "${nvme_list[@]}"; do read -r -u9
    {
        __temp_logfile=$fifo_dir/$(echo "$Index" | sed 's/\//#/g')
        __flag=0
        {
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            nvme_id=$(echo "$Index" | grep -Eo "/dev/nvme[0-9]+")
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: nvme fw-download $Index --fw=$bridge_fw"
                nvme fw-download "$Index" --fw="$bridge_fw"
                echo "【command】bridge: nvme fw-commit $Index -a 1 -s 0"
                nvme fw-commit "$Index" -a 1 -s 0
                echo "【command】bridge: nvme reset $nvme_id"
                nvme reset "$nvme_id"
            done 
            echo "【command】nvme fw-download $Index --fw=$fw_file"
            nvme fw-download "$Index" --fw="$fw_file" || __flag=1 
            echo "【command】nvme fw-commit $Index -a 1 -s 0"
            cmd_result=$(nvme fw-commit "$Index" -a 1 -s 0)
            echo "$cmd_result"
            echo "$cmd_result" | grep -i "Success" >/dev/null || __flag=1
            echo "【command】nvme reset $nvme_id" 
            nvme reset "$nvme_id"
            echo "Index=$Index, __flag=$__flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$__temp_logfile".log 2>&1
        mv "$__temp_logfile".log "$__temp_logfile=$__flag".log 
        echo 6 >&9
    } &
    done
}


# dera nvme盘
dsmart_hardware() {
    logger_info "$CURRENT_PATH/dsmart info | grep -iaE $HdModel"
    "$CURRENT_PATH"/dsmart info | grep -iaE "$HdModel" >>"$LOGGER_FILE" || repo_flag=1
}


dsmart_version() {
    "$CURRENT_PATH"/dsmart info | grep -iaE "$HdModel" | awk '{print $NF}' >"$CURRENT_PATH"/version.txt
}


dsmart_update() {
    mapfile -t nvme_list < <("$CURRENT_PATH"/dsmart info | grep -iaE "$HdModel" | awk '{print $1}' | sed '/^\s*$/d')
    [ -z "${nvme_list[*]}" ] && repo_flag1=1
    for Index in "${nvme_list[@]}"; do read -r -u9
    {
        __temp_logfile=$fifo_dir/$(echo "$Index" | sed 's/\//#/g')
        __flag=0
        {
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            nvme_id=$(echo "$Index" | grep -Eo "/dev/nvme[0-9]+")
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: echo y | $CURRENT_PATH/dsmart update-fw $Index -f $bridge_fw -s 1"
                echo y | "$CURRENT_PATH"/dsmart update-fw "$Index" -f "$bridge_fw" -s 1
            done 
            echo "【command】echo y | $CURRENT_PATH/dsmart update-fw $Index -f $fw_file -s 1"
            echo y | "$CURRENT_PATH"/dsmart update-fw "$Index" -f "$fw_file" -s 1 || __flag=1 
            echo "Index=$Index, __flag=$__flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$__temp_logfile".log 2>&1
        mv "$__temp_logfile".log "$__temp_logfile=$__flag".log 
        echo 6 >&9
    } &
    done
}


# 存储格式：盘符(如/dev/sg0) sn model version
smartctl_info() {
    # smartctl -i /dev/nvme0n1
    # smartctl 6.6 2017-11-05 r4594 [x86_64-linux-4.18.0-193.el8.x86_64] (local build)
    # Copyright (C) 2002-17, Bruce Allen, Christian Franke, www.smartmontools.org

    # === START OF INFORMATION SECTION ===
    # Model Number:                       PU7T6T0166500
    # Serial Number:                      10030038421911001L
    # Firmware Version:                   6025
    # PCI Vendor/Subsystem ID:            0x1e81
    # IEEE OUI Identifier:                0x044a50
    # Total NVM Capacity:                 7,681,501,126,656 [7.68 TB]
    # Unallocated NVM Capacity:           0
    # Controller ID:                      1
    # Number of Namespaces:               64
    # Namespace 1 Size/Capacity:          7,681,501,126,656 [7.68 TB]
    # Namespace 1 Formatted LBA Size:     512
    # Local Time is:                      Tue Mar 15 10:06:02 2022 CST
    logger_aux "【ARCCONF GET DISK INFORMATION】"

    local model_filter='device model|^product|model number'
    local sn_filter='serial number'
    local version_filter='firmware version|^revision'
    mapfile -t smartctl_sg_list < <(echo "$(
        lsscsi -g 2> /dev/null | grep disk | awk '{print $NF}' | cut -d/ -f3
        ls /sys/class/block | grep -v virtual | tr 'p' '\n' | grep -i nvme
    )" | sort -u | sed '/^\s*$/d')
    smartctl_lsscsi_disk_list=$(lsscsi -g 2> /dev/null | grep -i "disk")

    add_disk_info() {
        __model=$(echo "$2" | grep -E -i "$model_filter" | cut -d: -f2 | awk '{$1=$1;print}' | sed "s/\W\|_/-/g")
        __sn=$(echo "$2" | grep -E -i "$sn_filter" | cut -d: -f2 | awk '{$1=$1;print}')
        __version=$(echo "$2" | grep -E -i "$version_filter" | cut -d: -f2 | awk '{$1=$1;print}')
        # __model/__sn/__version 这3个值都不为空，且都只有1行
        if [ -n "${__sn}" ] && [ -n "${__model}" ] && [ -n "${__version}" ] && 
            [ "$(echo "$__model" | wc -l)" -eq 1 ] && [ "$(echo "$__sn" | wc -l)" -eq 1 ] && [ "$(echo "$__version" | wc -l)" -eq 1 ]; then
            smartctl_result[${#smartctl_result[*]}]="$1 ${__sn} ${__model} ${__version}"
            return 0
        elif [ -n "${__sn}" ] && [ -n "${__model}" ] && [ -n "${__version}" ]; then
            logger_error "硬盘查询结果有问题：\nmodel=$__model\nsn=$__sn\nversion=$__version"
            return 1
        else
            return 1
        fi
    }

    for __sgx in "${smartctl_sg_list[@]}"; do
        __sgx="/dev/$__sgx"
        __info=$(smartctl -i "$__sgx" 2>&1)
        # 常规方式可以获取则直接下一次循环
        if [ -n "$__info" ]; then
            logger_aux "smartctl -i $__sgx\n$__info\n"
            add_disk_info "$__sgx" "$__info" && continue
        fi
        # P430&9311的成员盘
        if [ "$(echo "$smartctl_lsscsi_disk_list" | grep -i "$__sgx" | awk '{print $(NF-1)}')" = "-" ]; then
            # 这里不判断是SAS还是SATA盘
            __scsi_info=$(smartctl -d scsi -i "$__sgx" 2>&1)
            if [ -n "$__scsi_info" ]; then
                logger_aux "smartctl -d scsi -i $__sgx\n$__scsi_info\n"
                add_disk_info "$__sgx" "$__scsi_info" && continue
            fi
            __sat_info=$(smartctl -d sat -i "$__sgx" 2>&1)
            if [ -n "$__sat_info" ]; then
                logger_aux "smartctl -d scsi -i $__sgx\n$__sat_info\n"
                add_disk_info "$__sgx" "$__sat_info" && continue
            fi
        fi
        # HBA1000&P460&H460的成员盘
        if echo "$smartctl_lsscsi_disk_list" | grep -i "$__sgx" | grep -i "LOGICAL" >/dev/null; then
            logical_disk="$__sgx"
            continue
        fi
    done

    if [ -n "$logical_disk" ]; then
        for ((__i = 0; __i <= "$sg_num"; __i++)); do
            __cciss_info=$(smartctl -d cciss,"$__i" -i "$logical_disk" 2>&1)
            if [ -n "$__cciss_info" ]; then
                logger_aux "smartctl -d cciss,"$__i" -i $logical_disk\n$__cciss_info\n"
                add_disk_info "$logical_disk" "$__cciss_info" && continue
            fi
        done
    fi

    # 数组去重 a[$2]的a不是整行，是另外一个字典
    mapfile -t smartctl_result < <(for item in "${smartctl_result[@]}"; do echo "$item"; done | awk '{if(!a[$2])print $0}{a[$2]++}')
    logger_aux "前置信息：\n盘符： ${smartctl_sg_list[*]}\nlsscsi查询：\n${smartctl_lsscsi_disk_list}\nsg num：${sg_num}\n\n"
}


# 存储格式：clt_number,TL(如1,0,8) sn model version
arcconf_info() {
    logger_aux "【SMARTCTL GET DISK INFORMATION】"
    # 记录sg设备的个数，供smartctl使用，故该函数需要在smartctl_info前执行
    sg_num=0
    mapfile -t arcconf_cardinfo_list < <("$ARCCONF" list 2>&1 | grep -i -E "RAID|SmartIOC|2100|HBA" | sed '/^\s*$/d')
    for __cardinfo in "${arcconf_cardinfo_list[@]}"; do
        __clt_number=$(echo "$__cardinfo" | cut -d: -f1 | awk '{print $2}')
        __config=$("$ARCCONF" getconfig "$__clt_number" pd 2>&1)
        #mapfile -t slot_info_list < <(echo "$__config" | grep -i -E ': Enclosure|: Connector' | grep -i -o "Slot ." | sed '/^\s*$/d')
        __num=$(echo "$__config" | grep -i -c "reported channel")
        sg_num=$((sg_num + __num))
        mapfile -t slot_info_list < <(echo "$__config" | grep -i -E "Enclosure.*Slot [0-9]*|Connector.*Slot [0-9]*" | sed '/^\s*$/d')
        for __disk in "${slot_info_list[@]}"; do
            # __info=$(echo "$__config" | grep -i -E -C5 ": Enclosure.*${__slot}|: Connector.*${__slot}")
            __info=$(echo "$__config" | grep -i -C5 "$__disk" | awk '{$1=$1;print}')
            __TL=$(echo "$__info" | grep -i "Reported Channel,Device(T:L)" | awk '{print $NF}' | awk -F '(' '{print $1}' | awk '{$1=$1;print}')
            __model=$(echo "$__info" | grep -E -i '^product|^model' | cut -d: -f2 | awk '{$1=$1;print}' | sed "s/\W\|_/-/g")
            __sn=$(echo "$__info" | grep -i "^Serial" | cut -d: -f2 | awk '{$1=$1;print}')
            __version=$(echo "$__info" | grep -i "^Firmware" | cut -d: -f2 | awk '{$1=$1;print}')

            # __model/__sn/__version 这3个值都不为空，且都只有1行
            if [ -n "${__sn}" ] && [ -n "${__model}" ] && [ -n "${__version}" ] && 
                [ "$(echo "$__model" | wc -l)" -eq 1 ] && [ "$(echo "$__sn" | wc -l)" -eq 1 ] && [ "$(echo "$__version" | wc -l)" -eq 1 ]; then
                arcconf_result[${#arcconf_result[*]}]="${__clt_number},${__TL} ${__sn} ${__model} ${__version}"
            elif [ -n "${__sn}" ] && [ -n "${__model}" ] && [ -n "${__version}" ]; then
                logger_error "硬盘查询结果有问题：\nmodel=$__model\nsn=$__sn\nversion=$__version"
            fi
            # 问题FAQ：P430不支持硬盘升级
        done
        logger_aux "阵列卡${__clt_number}\n卡信息：\n$__cardinfo\n\n$ARCCONF getconfig $__clt_number pd:\n$__config\n"
    done
    mapfile -t arcconf_result < <(for item in "${arcconf_result[@]}"; do echo "$item"; done | awk '{if(!a[$2])print $0}{a[$2]++}')
}


# 存储格式：hd(如64:1) sn model version
storcli64_info() {
    # "Drive /c.*/s.*attributes" 代表一个设备，每个设备11行信息
    # Drive /c0/e65/s19 Device attributes :
    # ===================================
    # SN = 48K0A00EFN6F
    # Manufacturer Id = TOSHIBA
    # Model Number = AL14SXB30EN
    # NAND Vendor = NA
    # WWN = 500003989860C770
    # Firmware Revision = 1401
    # Firmware Release Number = N/A
    # Raw size = 279.396 GB [0x22ecb25c Sectors]
    # Coerced size = 278.875 GB [0x22dc0000 Sectors]
    # --
    logger_aux "【STORCLI64 GET DISK INFORMATION】"
    hd_list_info=$(echo "$(
        "$STORCLI64" /call/eall/sall show all
        "$STORCLI64" /call/sall show all
    )" | grep -i "Drive /c.*/s.*attributes" -A10)

    mapfile -t hd_list < <(echo "$hd_list_info" | grep -i "Drive /c.*/s.*attributes" | grep -o "/c.*/s[0-9]*" | sed '/^\s*$/d')
    # 获取所有的设备号，如/c0/e65/s0
    for __hd in "${hd_list[@]}"; do
        __info=$(echo "$hd_list_info" | grep -i "Drive ${__hd} .*attributes" -A10)
        __sn=$(echo "$__info" | grep -i -w "^SN" | awk -F= '{print $2}' | awk '{$1=$1;print}')
        __model=$(echo "$__info" | grep -i -w "Model" | awk -F= '{print $2}' | awk '{$1=$1;print}' | sed "s/\W\|_/-/g")
        __version=$(echo "$__info" | grep -i -w "Revision" | awk -F= '{print $2}' | awk '{$1=$1;print}')
        # __model/__sn/__version 这3个值都不为空，且都只有1行
        if [ -n "${__sn}" ] && [ -n "${__model}" ] && [ -n "${__version}" ] && 
            [ "$(echo "$__model" | wc -l)" -eq 1 ] && [ "$(echo "$__sn" | wc -l)" -eq 1 ] && [ "$(echo "$__version" | wc -l)" -eq 1 ]; then
            # 单块盘： /c0/e65/s0 48K0A00EFN6F AL14SXB30EN 1401
             storcli64_result[${#storcli64_result[*]}]="${__hd} ${__sn} ${__model} ${__version}"
        elif [ -n "${__sn}" ] && [ -n "${__model}" ] && [ -n "${__version}" ]; then
            logger_error "硬盘查询结果有问题：\nmodel=$__model\nsn=$__sn\nversion=$__version"
        fi
    done
    mapfile -t storcli64_result < <(for item in "${storcli64_result[@]}"; do echo "$item"; done | awk '{if(!a[$2])print $0}{a[$2]++}')
    logger_aux "$STORCLI64 /call/eall/sall show all：\n$hd_list_info\n"
}


# 存储格式：pd sn model version
mnv_cli_info() {
    # ./mnv_cli info -o pd
    # PD ID:                        0
    # Model:                        SSSTC CA5-8D256
    # Serial:                       00221730058H
    # Sector Size:                  512bytes
    # LBA:                          500118192
    # Size:                         238 GB
    # SSD backend RC/Slot ID:       0
    # SSD backend Namespace ID:     1
    # Firmware version:             CQ23802
    # Status:                       Idle
    # Assigned:                     Yes
    # SMART Critical                No
    #
    # PD ID:                        1
    # Model:                        SSSTC CA5-8D256
    # Serial:                       002217300583
    # Sector Size:                  512bytes
    # LBA:                          500118192
    # Size:                         238 GB
    # SSD backend RC/Slot ID:       1
    # SSD backend Namespace ID:     1
    # Firmware version:             CQ23802
    # Status:                       Idle
    # Assigned:                     Yes
    # SMART Critical                No
    logger_aux "MNV_CLI GET DISK INFORMATION】"
    mnv_cli_list_info=$("$MNVCLI" info -o pd | grep -i "^PD" -A10)
    mapfile -t mnv_cli_list < <(echo "$mnv_cli_list_info" | grep -i -w "^PD" | awk '{print $NF}' | sed '/^\s*$/d')
    for __mnv_cli in "${mnv_cli_list[@]}"; do
        __info=$(echo "$mnv_cli_list_info" | grep -i "PD ID: *${__mnv_cli}$" -A10)
        # echo "$__info" | grep -iaE "$HdModel" > /dev/null || continue
        __sn=$(echo "$__info" | grep -i -w "^Serial" | awk '{print $NF}'| awk '{$1=$1;print}')
        __model=$(echo "$__info" | grep -i -w "^Model" | awk '{print $NF}' | awk '{$1=$1;print}' | sed "s/\W\|_/-/g")
        __version=$(echo "$__info" | grep -i -w "version" | awk '{print $NF}' | awk '{$1=$1;print}')
        # __model/__sn/__version 这3个值都不为空，且都只有1行
        if [ -n "${__sn}" ] && [ -n "${__model}" ] && [ -n "${__version}" ] && 
            [ "$(echo "$__model" | wc -l)" -eq 1 ] && [ "$(echo "$__sn" | wc -l)" -eq 1 ] && [ "$(echo "$__version" | wc -l)" -eq 1 ]; then
            mnv_cli_result[${#mnv_cli_result[*]}]="${__mnv_cli} ${__sn} ${__model} ${__version}"
        elif [ -n "${__sn}" ] && [ -n "${__model}" ] && [ -n "${__version}" ]; then
            logger_error "硬盘查询结果有问题：\nmodel=$__model\nsn=$__sn\nversion=$__version"
        fi
    done
    mapfile -t mnv_cli_result < <(for item in "${mnv_cli_result[@]}"; do echo "$item"; done | awk '{if(!a[$2])print $0}{a[$2]++}')
    logger_aux "$MNVCLI info -o pd\n$mnv_cli_list_info\n"
}

is_exist_SN() {
    local SN=$1
    if [ $# = 1 ]; then
        for vender_SN in "${sn_in_vender_tool[@]}"; do
            is_exist_SN "$SN" "$vender_SN" && return 0
        done
        return 1
    else
       local SN2=$2
       if [[ $SN =~ $SN2 ]] || [[ $SN2 =~ $SN ]]; then
          return 0
       else
          return 1
       fi
    fi
}


is_lsi_device_ok() {
    local end_time=$(("$(date '+%s')" + 90))
    while [ "$(date '+%s')" -le "$end_time" ]
    do
        echo "$STORCLI64 $@ show"
        "$STORCLI64" "$@" show | tee -a "$LOGGER_FILE" | grep -q "^Status.*Success" && return 0
        sleep 2
        [ "$tmp_flag" = 1 ] && repo_flag=1
        return 1
    done
}


# 升级逻辑是通过SN判断，若该SN的盘厂商工具已升级，则阵列卡中被过滤，反之阵列卡会调用升级逻辑

raid_handler() {
    arcconf_info
    storcli64_info
    smartctl_info
    mnv_cli_info

    smartctl_print=$(for i in "${smartctl_result[@]}"; do echo "$i"; done)
    arcconf_print=$(for i in "${arcconf_result[@]}"; do echo "$i"; done)
    storcli64_print=$(for i in "${storcli64_result[@]}"; do echo "$i"; done)
    mnv_cli_print=$(for i in "${mnv_cli_result[@]}"; do echo "$i"; done)
    logger_aux "【阵列卡查询结果】\nSMARTCTL：\n${smartctl_print}\nARCCONF：\n${arcconf_print}\nSTORCLI64：\n${storcli64_print}\nMNV_CTL：\n${mnv_cli_print}"

    if [ "$1" = 'hardware' ]; then
        array_new=("${arcconf_result[@]}" "${storcli64_result[@]}" "${smartctl_result[@]}" "${mnv_cli_result[@]}")
        for __disk in "${array_new[@]}"; do
            if echo "${__disk}" | grep -iaE "$HdModel" >/dev/null; then
                logger_info "硬件在位：${__disk}"
                repo_flag=0
                return
            fi
        done
        repo_flag=1
        return
    elif [ "$1" = 'version' ]; then
        array_new=("${arcconf_result[@]}" "${storcli64_result[@]}" "${smartctl_result[@]}" "${mnv_cli_result[@]}")
        for __disk in "${array_new[@]}"; do
            if echo "${__disk}" | grep -iaE "$HdModel" >/dev/null; then
                logger_info "获取版本：${__disk}"
                echo "${__disk}" | awk '{print $NF}' >>"$CURRENT_PATH"/version.txt
            fi
        done
        if [ -f "$CURRENT_PATH/manager.xml" ]; then
            xml_version=$(grep -i '<version value=' "$CURRENT_PATH/manager.xml" | cut -d\" -f2 | cut -d\' -f2)
            xml_width=$(echo "$xml_version" | wc -L)
            mapfile -t version_txt_str < <(awk '{$1=$1;print}' version.txt | sort -u)
            cat /dev/null > version.txt

            # 1
            for _disk in "${version_txt_str[@]}"; do
                _len=$(echo "$_disk" | wc -L)
                if [ "$xml_width" -gt "$_len" ]; then
                    offset_width=$((xml_width-_len))
                    echo "$(echo "$xml_version" | cut -c -$offset_width)$_disk" >>"$CURRENT_PATH"/version.txt
                else 
                    echo "$_disk" >>"$CURRENT_PATH"/version.txt
                fi
            done

            # 2
            # disk_width_list=$(echo "$version_txt_str" |awk '{print length($0)}')
            # num = 0
            # for __disk_width in "${disk_width_list[@]}"; do
            #     ((num++))
            #     cver=$(echo "$version_txt_str" | sed -n$num)
            #     if [ "$xml_width" -gt "$__disk_width" ]; then
            #         offset_width=$((xml_width-__disk_width))
            #         echo "$(echo $xml_version | cut -c -$offset_width)$cver" >>"$CURRENT_PATH"/version.txt
            #         continue
            #     fi
            # done

        fi
    elif [ "$1" = 'update' ]; then
        wait
        for __disk in "${smartctl_result[@]}"; do
            echo "${__disk}" | grep -iavE "$HdModel" >/dev/null && continue
            repo_flag1=0
            SN=$(echo "${__disk}" | awk '{print $2}')
            is_exist_SN "$SN" && continue
            smartctl_get_sn[${#smartctl_get_sn[*]}]="$SN"
        done
        for __disk in "${arcconf_result[@]}"; do 
            echo "${__disk}" | grep -iavE "$HdModel" >/dev/null && continue
            repo_flag1=0
            SN=$(echo "${__disk}" | awk '{print $2}')
            is_exist_SN "$SN" && continue
            # 删除arcconf匹配到的SN，最后smartctl_get_sn剩余的SN还需要特殊处理
            for smartctl_sn_id in "${!smartctl_get_sn[@]}"; do
                is_exist_SN "${smartctl_get_sn[$smartctl_sn_id]}" "$SN" && unset "smartctl_get_sn[$smartctl_sn_id]"
            done
            pmc_disk_list[${#pmc_disk_list[*]}]=$__disk
        done
        # 当arcconf查询的model号不全时，通过smartctl校正
        [ -n "${smartctl_get_sn[*]}" ] && logger_info "arcconf查到的model不全，使用smartctl校正，列表如下：${smartctl_get_sn[*]}"
        for smartctl_sn in "${smartctl_get_sn[@]}"; do 
            for __disk in "${arcconf_result[@]}"; do
                SN=$(echo "${__disk}" | awk '{print $2}')
                is_exist_SN "$SN" "$smartctl_sn" && pmc_disk_list[${#pmc_disk_list[*]}]=$__disk && break
            done
        done
        for __disk in "${storcli64_result[@]}"; do
            echo "${__disk}" | grep -iavE "$HdModel" >/dev/null && continue
            repo_flag1=0
            SN=$(echo "${__disk}" | awk '{print $2}')
            is_exist_SN "$SN" && continue
            lsi_disk_list[${#lsi_disk_list[*]}]=$__disk
        done
        for __disk in "${mnv_cli_result[@]}"; do
            echo "${__disk}" | grep -iavE "$HdModel" >/dev/null && continue
            repo_flag1=0
            SN=$(echo "${__disk}" | awk '{print $2}')
            is_exist_SN "$SN" && continue
            mnv_disk_list[${#mnv_disk_list[*]}]=$__disk
        done
        # 开始升级
        # pmc阵列卡不同线程升级有干扰，总体时间相差不大，也有可能是跨度版本不够或盘数量不够
        for Index in "${pmc_disk_list[@]}"; do 
        {
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            __slot_info=$(echo "${Index}" | awk '{print $1}')
            controller_id=$(echo "$__slot_info" | cut -d, -f1)
                
            tl1=$(echo "$__slot_info" | cut -d, -f2)
            tl2=$(echo "$__slot_info" | cut -d, -f3)
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: echo y | $ARCCONF imageupdate $controller_id device $tl1 $tl2 32768 ${bridge_fw}"
                echo y | "$ARCCONF" imageupdate "$controller_id" device "$tl1" "$tl2" 32768 "${bridge_fw}"
            done
            echo "【command】echo y | $ARCCONF imageupdate $controller_id device $tl1 $tl2 32768 $fw_file"
            cmd_result=$(echo y | "$ARCCONF" imageupdate "$controller_id" device "$tl1" "$tl2" 32768 "$fw_file")
            echo "$cmd_result"
            echo "$cmd_result" | grep -i "Succeeded" >/dev/null || repo_flag=1
            echo "Index=$Index, repo_flag=$repo_flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$LOGGER_FILE" 2>&1
        done
        for Index in "${lsi_disk_list[@]}"; do 
        {   
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            mapfile -t __slot_info < <(echo "${Index}" | awk '{print $1}' | sed 's#/# /#g' | awk '{$1=$1;print}' | tr ' ' '\n' | sed '/^\s*$/d')
            
            for bridge_fw in "${fw_bridge_files[@]}"; do
                is_lsi_device_ok "${__slot_info[@]}" || continue
                echo "【command】bridge: $STORCLI64 ${__slot_info[*]} download src=${bridge_fw}"
                "$STORCLI64" "${__slot_info[@]}" download src="${bridge_fw}"
            done
            
            if ! is_lsi_device_ok "${__slot_info[@]}"; then
                repo_flag=1
                continue
            fi
            echo "【command】$STORCLI64 ${__slot_info[*]} download src=$fw_file"
            "$STORCLI64" "${__slot_info[@]}" download src="$fw_file" || repo_flag=1
            echo "Index=$Index, repo_flag=$repo_flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$LOGGER_FILE" 2>&1
        done
        # 如果使用了LSI的工具升级，那么等待60s结束
        [ -n "${lsi_disk_list[*]}" ] && sleep 60

        for Index in "${mnv_disk_list[@]}"; do 
        {   
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            pd_id=$(echo "${Index}" | awk '{print $1}')
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: $MNVCLI flash -o pd -i $pd_id -f ${bridge_fw} -s 2 -c 1"
                "$MNVCLI" flash -o pd -i "$pd_id" -f "${bridge_fw}" -s 2 -c 1
            done
            echo "【command】: $MNVCLI flash -o pd -i $pd_id -f $fw_file -s 2 -c 1"
            "$MNVCLI" flash -o pd -i "$pd_id" -f "$fw_file" -s 2 -c 1 || repo_flag=1
            echo "Index=$Index, repo_flag=$repo_flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$LOGGER_FILE" 2>&1
        done

    elif [ "$1" = 'get_model' ]; then
        {
            array_new=("${smartctl_result[@]}" "${storcli64_result[@]}" "${arcconf_result[@]}" "${mnv_cli_result[@]}")
            for item in "${array_new[@]}"; do [ -n "$item" ] && echo "$item"; done | awk '{print $3}' | sort -u | xargs | sed 's/[[:space:]]/#/g' > "$CURRENT_PATH"/model.log
        }
    fi
}


# 西数
wdckit_hardware() {
    mkdir /opt/wdc >/dev/null 2>&1
    \cp -rf "$CURRENT_PATH"/wdckit /opt/wdc/
    logger_info "$CURRENT_PATH/wdckit/wdckit show | grep -iaE $HdModel"
    "$CURRENT_PATH"/wdckit/wdckit show | grep -iaE "$HdModel" >>"$LOGGER_FILE" || repo_flag=1
    [ "$repo_flag" = 1 ] && raid_handler "$script_type"
}


wdckit_version() {
    "$CURRENT_PATH"/wdckit/wdckit show | grep -iaE "$HdModel" | awk '{print $(NF-1)}' >"$CURRENT_PATH"/version.txt
    raid_handler "$script_type"

}


wdckit_update() {
    # DUT   Device      Port    Capacity    State   BootDevice  Serial Number           Model Number    Firmware    Lnk Spd Cap/Cur
    # 8     /dev/sdi    SAS     1.20 TB     Good    No          WFK7TQ170000K0432PXD    ST1200MM0129    C0E4        Gen4,Gen4/Gen4,Gen4
    
    # wdckit工具存在问题，无法根据工具返回来判断升级是否成功，厂商FAE的临时规避方案：在升级后检查版本是否生效
    disk_info=$("$CURRENT_PATH"/wdckit/wdckit show | grep -iaE "$HdModel" | grep -ia "/dev/sd" )
    mapfile -t __vender_tool_info < <(echo "$disk_info" | awk '{print $2}' | sed '/^\s*$/d')

    for Index in "${__vender_tool_info[@]}"; do
        sn_in_vender_tool[${#sn_in_vender_tool[*]}]=$(echo "$disk_info" | grep -ia "$Index" | awk '{print $8}')
    done

    # 若厂商工具查不到硬盘，直接走到阵列卡的逻辑
    if [ -z "${__vender_tool_info[*]}" ]; then
        repo_flag1=1
        raid_handler "$script_type"
        return
    fi

    for bridge_fw in "${fw_bridge_files[@]}"; do
        logger_info "bridge_fw: $bridge_fw"
        logger_info "$CURRENT_PATH/wdckit/wdckit update ${__vender_tool_info[*]} -f $bridge_fw"
        "$CURRENT_PATH"/wdckit/wdckit update "${__vender_tool_info[@]}" -f "$bridge_fw" >>"$LOGGER_FILE" 2>&1
    done

    # 优化升级方式为一把升级所有的盘
    logger_info "$CURRENT_PATH/wdckit/wdckit update ${__vender_tool_info[*]} -f $fw_file"
    "$CURRENT_PATH"/wdckit/wdckit update "${__vender_tool_info[@]}" -f "$fw_file" >>"$LOGGER_FILE" 2>&1 || repo_flag=1
    
    # 如果升级工具报失败，则等待120s，查看版本是否已升级到目标版本
    if [ "$repo_flag" = 1 ]; then
        to_be_version=$(grep -i '<version value=' "$CURRENT_PATH/manager.xml" | cut -d\" -f2 | cut -d\' -f2)
        [ -z "$to_be_version" ] && return
        logger_info "工具升级异常，等待120s，检查版本是否正常升级到目标"
        sleep 120
        logger_info "$CURRENT_PATH/wdckit/wdckit show | grep -iaE $HdModel"
        "$CURRENT_PATH"/wdckit/wdckit show | grep -iaE "$HdModel" | tee -a "$LOGGER_FILE" | awk '{print $(NF-1)}' | grep -v "$to_be_version" > /dev/null || repo_flag=0
        if [ "$repo_flag" = 0 ] ;then
            logger_info "通过检查版本的方式规避了问题！"
        else
            logger_info "通过检查版本的方式没有规避问题！是否等待时间不够或者硬盘有问题？"
        fi
    fi
    
    raid_handler "$script_type"

}


# 希捷
SeaChest_hardware() {
    logger_info "$CURRENT_PATH/SeaChest -s | grep -iaE $HdModel"
    "$CURRENT_PATH"/SeaChest -s | grep -iaE "$HdModel" >>"$LOGGER_FILE" || repo_flag=1
    [ "$repo_flag" = 1 ] && raid_handler "$script_type"
}


SeaChest_version() {
    "$CURRENT_PATH"/SeaChest -s | grep -iaE "$HdModel" | awk '{print $NF}' >"$CURRENT_PATH"/version.txt
    raid_handler "$script_type"
}


SeaChest_update() {
    # Vendor    Handle      Model Number    Serial Number   FwRev
    # SEAGATE   /dev/sg8    ST1200MM0129    WFK7TQ17        C0E4
    
    disk_info=$("$CURRENT_PATH"/SeaChest -s | grep -iaE "$HdModel")
    mapfile -t __vender_tool_info < <(echo "$disk_info" | awk '{print $2}' | sed '/^\s*$/d')
    [ -z "${__vender_tool_info[*]}" ] && repo_flag1=1
    for Index in "${__vender_tool_info[@]}"; do read -r -u9  
    {
        __temp_logfile=$fifo_dir/$(echo "$Index" | sed 's/\//#/g')
        __flag=1
        {
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: $CURRENT_PATH/SeaChest --downloadFW $bridge_fw -d $Index"
                "$CURRENT_PATH"/SeaChest --downloadFW "$bridge_fw" -d "$Index"
            done
            echo "【command】$CURRENT_PATH/SeaChest --downloadFW $fw_file -d $Index"
            "$CURRENT_PATH"/SeaChest --downloadFW "$fw_file" -d "$Index" && __flag=0
            echo "Index=$Index, __flag=$__flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$__temp_logfile".log 2>&1
        mv "$__temp_logfile".log "$__temp_logfile=$__flag".log 
        echo 6 >&9
    } &
        sn_in_vender_tool[${#sn_in_vender_tool[*]}]=$(echo "$disk_info" | grep -ia "$Index" | awk '{print $(NF-1)}')
    done
    raid_handler "$script_type"
}


# 东芝
tsbdrv_hardware() {
    logger_info "export LD_LIBRARY_PATH=$CURRENT_PATH/tsbdrv"
    export LD_LIBRARY_PATH="$CURRENT_PATH"/tsbdrv
    logger_info "$CURRENT_PATH/tsbdrv/tsbdrv query all | grep -iaE $HdModel"
    "$CURRENT_PATH"/tsbdrv/tsbdrv query all | grep -iaE "$HdModel" >>"$LOGGER_FILE" || repo_flag=1
    [ "$repo_flag" = 1 ] && raid_handler "$script_type"
}


tsbdrv_version() {
    logger_info "export LD_LIBRARY_PATH=$CURRENT_PATH/tsbdrv"
    export LD_LIBRARY_PATH="$CURRENT_PATH"/tsbdrv
    "$CURRENT_PATH"/tsbdrv/tsbdrv query all | grep -iaE "$HdModel" | awk '{print $3}' >"$CURRENT_PATH"/version.txt
    raid_handler "$script_type"
}


tsbdrv_update() {
    # tsbdrv query all
    # PHYSICAL-DRIVE    UNIT-STATUS     FW-VER      MODEL_NUMBER    SERIAL-NUMBER   TRANSPORT   DEV-TYPE
    # /dev/sda          Ready           1403        AL15SEB060N     4990A0E8FM9F    SCSI        SCSI
    logger_info "export LD_LIBRARY_PATH=$CURRENT_PATH/tsbdrv"
    export LD_LIBRARY_PATH="$CURRENT_PATH"/tsbdrv
    
    disk_info=$("$CURRENT_PATH"/tsbdrv/tsbdrv query all | grep -iaE "$HdModel" | grep -ia "/dev/sd")
    mapfile -t __vender_tool_info < <(echo "$disk_info" | awk '{print $1}' | sed 's/\/dev\///g' | sed '/^\s*$/d')
    [ -z "${__vender_tool_info[*]}" ] && repo_flag1=1
    for Index in "${__vender_tool_info[@]}"; do read -r -u9  
    {
        __temp_logfile=$fifo_dir/$(echo "$Index" | sed 's/\//#/g')
        __flag=1
        {
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: echo y | $CURRENT_PATH/tsbdrv/tsbdrv firmware download $Index $bridge_fw"
                echo y | "$CURRENT_PATH"/tsbdrv/tsbdrv firmware download "$Index" "$bridge_fw"
            done
            echo "【command】echo y | $CURRENT_PATH/tsbdrv/tsbdrv firmware download $Index $fw_file"
            echo y | "$CURRENT_PATH"/tsbdrv/tsbdrv firmware download "$Index" "$fw_file" && __flag=0
            echo "Index=$Index, __flag=$__flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$__temp_logfile".log 2>&1
        mv "$__temp_logfile".log "$__temp_logfile=$__flag".log 
        echo 6 >&9
    } &
        sn_in_vender_tool[${#sn_in_vender_tool[*]}]=$(echo "$disk_info" | grep -ia "$Index" | awk '{print $(NF-2)}')
    done
    raid_handler "$script_type"


}


# 英特尔
intelmas_hardware() {
    cd "$CURRENT_PATH" || exit
    logger_info "安装工具：rpm -ivh intelmas*rpm --replacepkgs --force"
    rpm -ivh intelmas*rpm --replacepkgs --force >> "$LOGGER_FILE" 2>&1
    rpm -q intelmas >/dev/null 2>&1 || logger_err "Tool install Failed! "
    logger_info "intelmas show -intelssd | grep -iaE $HdModel"
    intelmas show -intelssd | grep -iaE "$HdModel" >>"$LOGGER_FILE" || repo_flag=1
    [ "$repo_flag" = 1 ] && raid_handler "$script_type"
}


intelmas_version() {
    intelmas show -intelssd | grep -iaE "$HdModel" -B 4 | grep -ia 'Firmware :' | awk -F: '{print $2}' >"$CURRENT_PATH"/version.txt
    raid_handler "$script_type"
}


intelmas_update() {
    # intelmas show -intelssd
    # Capacity          : 3840.76GB
    # DevicePath        : /dev/sg2
    # DeviceStatus      : Healthy
    # Firmware          : 7CV10100
    # FirmwareUpdateAvailable: The Selected drive contains current firmware as of this tool release.
    # Index             : 1
    # MaximumLBA        : 7501476527
    # ModelNumber       : INTEL SSDSC2KG038TZ
    # PerCentOverProvisioned: 100.00
    # ProductFamily     : Intel SSD DC S4620 Series
    # SMARTEnabled      : True
    # SectorDataSize    : 512
    # SerialNumber      : BTYJ116500WW3P8DGN
    disk_info=$(intelmas show -intelssd | grep -iaE "$HdModel" -C5)
    mapfile -t __vender_tool_info < <(echo "$disk_info" | grep -ia "Index" | awk -F: '{print $2}' | awk '{$1=$1;print}' | sed '/^\s*$/d')
    [ -z "${__vender_tool_info[*]}" ] && repo_flag1=1
    for Index in "${__vender_tool_info[@]}"; do read -r -u9  
    {
        __temp_logfile=$fifo_dir/$(echo "$Index" | sed 's/\//#/g')
        __flag=1
        {
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: echo y | intelmas load -source $bridge_fw -intelssd $Index"
                echo y | intelmas load -source "$bridge_fw" -intelssd "$Index"
            done
            echo "【command】echo y | intelmas load -source $fw_file -intelssd $Index"
            echo y | intelmas load -source "$fw_file" -intelssd "$Index" && __flag=0
            echo "Index=$Index, __flag=$__flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$__temp_logfile".log 2>&1
        mv "$__temp_logfile".log "$__temp_logfile=$__flag".log 
        echo 6 >&9
    } &
        sn_in_vender_tool[${#sn_in_vender_tool[*]}]=$(echo "$disk_info" | grep -ia "Index *: *${Index}" -A7 | grep -ia "SerialNumber" | awk -F: '{print $2}' | awk '{$1=$1;print}')
    done
    raid_handler "$script_type"
}


# 镁光
msecli_hardware() {
    logger_info "$CURRENT_PATH/msecli -L |grep -iaE $HdModel"
    "$CURRENT_PATH"/msecli -L | grep -iaE "$HdModel" >>"$LOGGER_FILE" || repo_flag=1
    [ "$repo_flag" = 1 ] && raid_handler "$script_type" 
}


msecli_version() {
    "$CURRENT_PATH"/msecli -L | grep -iaE "$HdModel" -B 1 -A 2 | grep -ia "^FW" | awk -F: '{print $2}' >"$CURRENT_PATH"/version.txt
    raid_handler "$script_type" 
}


msecli_update() {
    # msecli -L
    # Device Name       : /dev/sdb
    # Model No          : Micron_5200_MTFODAK480TDC
    # Serial No         : 1825lD0583D2
    # FW-Rev            : DlMH032
    disk_info=$("$CURRENT_PATH"/msecli -L | grep -iaE "$HdModel" -B 1 -A 2 | grep -ia "/dev/sd" -A3)
    mapfile -t __vender_tool_info < <(echo "$disk_info" | grep -ia "Device Name" | cut -d: -f 2- | awk '{$1=$1;print}' | sed '/^\s*$/d')
    [ -z "${__vender_tool_info[*]}" ] && repo_flag1=1
    for Index in "${__vender_tool_info[@]}"; do read -r -u9  
    {
        __temp_logfile=$fifo_dir/$(echo "$Index" | sed 's/\//#/g')
        __flag=1
        {
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: echo y | $CURRENT_PATH/msecli -F -U $bridge_fw -n $Index"
                echo y | "$CURRENT_PATH"/msecli -F -U "$bridge_fw" -n "$Index"
            done
            echo "【command】echo y | $CURRENT_PATH/msecli -F -U $fw_file -n $Index"
            echo y | "$CURRENT_PATH"/msecli -F -U "$fw_file" -n "$Index" && __flag=0
            echo "Index=$Index, __flag=$__flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$__temp_logfile".log 2>&1
        mv "$__temp_logfile".log "$__temp_logfile=$__flag".log 
        echo 6 >&9
    } &
        sn_in_vender_tool[${#sn_in_vender_tool[*]}]=$(echo "$disk_info" | grep -ia "$Index" -A3 | grep -ia "Serial" | awk -F: '{print $2}' | awk '{$1=$1;print}')
    done
    raid_handler "$script_type"
}



# 三星
SSDManager_hardware() {
    cd "$CURRENT_PATH" || exit
    logger_info "安装工具：rpm -ivh mlocate*rpm --replacepkgs --force"
    rpm -ivh mlocate*rpm --replacepkgs --force >> "$LOGGER_FILE" 2>&1
    rpm -q mlocate >/dev/null 2>&1 || logger_err "Tool install Failed! "
    
    logger_info "$CURRENT_PATH/SSDManager -L | grep -iaE $HdModel"
    "$CURRENT_PATH"/SSDManager -L | grep -iaE "$HdModel" >>"$LOGGER_FILE" || repo_flag=1
    [ "$repo_flag" = 1 ] && raid_handler "$script_type"
}


SSDManager_version() {
    "$CURRENT_PATH"/SSDManager -L | grep -iaE "$HdModel" | cut -d '|' -f 8 >"$CURRENT_PATH"/version.txt
    raid_handler "$script_type"
}


SSDManager_update() {
    # SSDManager -L
    # |  Disk Path   |  Support  |  Protocol  |  Model             |  Serial Number      |  Part Number  |  Firmware  |   Driver  |  Status       |
    # |  /dev/sda    |  X        |  SATA      |  HFS480G3H2X069N   |  BJ12Q8076I0103C0N  |  -            |  410A1Z00  |   Inbox   |  Normal Mode  |
    disk_info=$("$CURRENT_PATH"/SSDManager -L | grep -iaE "$HdModel" | grep -ia "/dev/sd")
    mapfile -t __vender_tool_info < <(echo "$disk_info" | cut -d '|' -f 2 | sed 's/*//g' | awk '{$1=$1;print}' | sed '/^\s*$/d')
    [ -z "${__vender_tool_info[*]}" ] && repo_flag1=1
    for Index in "${__vender_tool_info[@]}"; do read -r -u9  
    {
        __temp_logfile=$fifo_dir/$(echo "$Index" | sed 's/\//#/g')
        __flag=1
        {
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: $CURRENT_PATH/SSDManager -d $Index -AF -p $bridge_fw --force"
                "$CURRENT_PATH"/SSDManager -d "$Index" -AF -p "$bridge_fw" --force
                echo "【command】bridge: $CURRENT_PATH/SSDManager -d $Index -SF -u -p $bridge_fw --force"
                "$CURRENT_PATH"/SSDManager -d "$Index" -SF -u -p "$bridge_fw" --force
            done
            echo "【command】$CURRENT_PATH/SSDManager -d $Index -AF -p $fw_file --force"
            "$CURRENT_PATH"/SSDManager -d "$Index" -AF -p "$fw_file" --force && __flag=0
            echo "【command】$CURRENT_PATH/SSDManager -d $Index -SF -u -p $fw_file --force"
            "$CURRENT_PATH"/SSDManager -d "$Index" -SF -u -p "$fw_file" --force  && __flag=0
            echo "Index=$Index, __flag=$__flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$__temp_logfile".log 2>&1
        mv "$__temp_logfile".log "$__temp_logfile=$__flag".log 
        echo 6 >&9
    } &
        sn_in_vender_tool[${#sn_in_vender_tool[*]}]=$(echo "$disk_info" | grep -ia "$Index" | cut -d '|' -f 6 | awk '{$1=$1;print}')
    done
    raid_handler "$script_type"
}


# 海力士
DriveManager_hardware() {
    cd "$CURRENT_PATH" || exit
    logger_info "安装工具：./DriveManager*run --mode unattended"
    ./DriveManager*run --mode unattended >> "$LOGGER_FILE" 2>&1
    
    logger_info "skhms-drive | grep -iaE $HdModel"
    skhms-drive | grep -iaE "$HdModel" >>"$LOGGER_FILE" || repo_flag=1
    [ "$repo_flag" = 1 ] && raid_handler "$script_type"
}


DriveManager_version() {
    skhms-drive | grep -iaE "$HdModel" | awk '{print $(NF-2)}' >"$CURRENT_PATH"/version.txt
    raid_handler "$script_type"
}


DriveManager_update() {
    # skhms-drive
    # ID    Device Name         Model Name      Serial Number       Fw Revision Capacoty
    # 0     /dev/sda            SE005-240GB-H   YMD1240JA204730043  YM120104    223.57 GB
    disk_info=$(skhms-drive | grep -iaE "$HdModel" | grep -ia "/dev/sd")
    mapfile -t __vender_tool_info < <(echo "$disk_info" | awk '{print $1}' | sed '/^\s*$/d')
    [ -z "${__vender_tool_info[*]}" ] && repo_flag1=1
    for Index in "${__vender_tool_info[@]}"; do read -r -u9
    {
        __temp_logfile=$fifo_dir/$(echo "$Index" | sed 's/\//#/g')
        __flag=1
        {
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: echo yes | skhms-drive firmware update $bridge_fw $Index"
                echo yes | skhms-drive firmware update "$bridge_fw" "$Index"
            done
            echo "【command】echo yes | skhms-drive firmware update $fw_file $Index"
            echo yes | skhms-drive firmware update "$fw_file" "$Index" && __flag=0
            echo "Index=$Index, __flag=$__flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$__temp_logfile".log 2>&1
        mv "$__temp_logfile".log "$__temp_logfile=$__flag".log 
        echo 6 >&9
    } &
        sn_in_vender_tool[${#sn_in_vender_tool[*]}]=$(echo "$disk_info" | grep -ia "$Index" | awk '{print $(NF-3)}')
    done
    raid_handler "$script_type"
}


# 忆联
unionmemory_hardware() {
    cd "$CURRENT_PATH" || exit
    logger_info "安装工具：rpm -ivh hdparm*rpm --replacepkgs --force"
    rpm -ivh um*rpm --replacepkgs --force >> "$LOGGER_FILE" 2>&1
    rpm -q umtool >/dev/null 2>&1 || logger_err "umtool install Failed!"
    rpm -q umsata >/dev/null 2>&1 || logger_err "umsata install Failed!"
    
    logger_info "umsata info -l && umtool info -l"
    umsata info -l 2>/dev/null | tee -a "$LOGGER_FILE" | grep -iaqE "$HdModel" || umtool info -l 2>/dev/null | tee -a "$LOGGER_FILE" | grep -iaqE "$HdModel" || repo_flag=1
    [ "$repo_flag" = 1 ] && raid_handler "$script_type"
}


unionmemory_version() {
    umsata info -l 2>/dev/null | grep -iaE "$HdModel" | awk '{print $NF}' >>"$CURRENT_PATH"/version.txt
    umtool info -l 2>/dev/null | grep -iaE "$HdModel" | awk '{print $NF}' >>"$CURRENT_PATH"/version.txt
    raid_handler "$script_type"
}


# # lsscsi
# [14:0:1:0]   disk    ATA      RS201480MF003LX  1086  /dev/sdb
# [14:0:3:0]   disk    UMIS     RA211960RK003LX  6022  /dev/sdd

# # umsata updatefw -d sdb
# Device      SN                        MN                    FW
# sdg         100300551227120021        RS201480MF003LX       1086
unionmemory_update() {
    sata_info=$(umsata info -l 2>/dev/null)
    sas_info=$(umtool info -l 2>/dev/null)

    mapfile -t __vender_tool_info < <(
        echo "$sata_info" | grep -iaE "$HdModel" | awk '{print $1}'
        echo "$sas_info" | grep -iaE "$HdModel" | awk '{print $1}'
        )
    [ -z "${__vender_tool_info[*]}" ] && repo_flag1=1
    
    for Index in "${__vender_tool_info[@]}"; do read -r -u9
    {
        __temp_logfile=$fifo_dir/$(echo "$Index" | sed 's/\//#/g')
        __flag=1
        {   
            local um
            if echo "$sata_info" | grep -iaE "^$Index" >/dev/null;then
                um=umsata
                sn=$(echo "sata_info" | grep -iaE "^$Index" |awk '{print $2}')
            elif echo "$sas_info" | grep -iaE "^$Index" >/dev/null;then
                um=umtool
                sn=$(echo "sas_info" | grep -iaE "^$Index" | awk '{print $2}')
            fi
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: echo Y |$um updatefw -d $Index -f $bridge_fw "
                echo Y |"$um" updatefw -d $Index -f "$bridge_fw"   
            done
            echo "【command】echo Y |$um updatefw -d $Index -f $fw_file "
            echo Y |"$um" updatefw -d $Index -f "$fw_file"  && __flag=0
            echo "Index=$Index, __flag=$__flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$__temp_logfile".log 2>&1
        mv "$__temp_logfile".log "$__temp_logfile=$__flag".log 
        echo 6 >&9
    } &
        sn_in_vender_tool[${#sn_in_vender_tool[*]}]=$sn
    done
    raid_handler "$script_type"
}




# 建兴、长江存储、德瑞
hdparm_hardware() {
    cd "$CURRENT_PATH" || exit
    logger_info "安装工具：rpm -ivh hdparm*rpm --replacepkgs --force"
    rpm -ivh hdparm*rpm --replacepkgs --force >> "$LOGGER_FILE" 2>&1
    rpm -q hdparm >/dev/null 2>&1 || logger_err "Tool install Failed! "
    
    logger_info "lsscsi | grep -iaE $HdModel"
    lsscsi 2> /dev/null | grep -iaE "$HdModel" >>"$LOGGER_FILE" || repo_flag=1
    [ "$repo_flag" = 1 ] && raid_handler "$script_type"
}


hdparm_version() {
    mapfile -t lsscsi_info < <(lsscsi 2> /dev/null | grep -iaE "$HdModel" | grep -ia "/dev/sd" | awk '{print $NF}' | sed '/^\s*$/d')
    for Index in "${lsscsi_info[@]}"; do
        hdparm -I "$Index" | grep -i "Firmware Revision" | awk -F: '{print $2}' >>"$CURRENT_PATH"/version.txt
    done
    raid_handler "$script_type"
}


# hdparm -I /dev/sdk
# /dev/sdk:

# ATA device, with non-removable media
#         Model Number:       DERAS32TGR01T9WT
#         Serial Number:      016203010FF2
#         Firmware Revision:  SCEMH5.0
hdparm_update() {
    mapfile -t __vender_tool_info < <(lsscsi 2> /dev/null | grep -iaE "$HdModel" | grep -ia "/dev/sd" | awk '{print $NF}'| sed '/^\s*$/d')
    [ -z "${__vender_tool_info[*]}" ] && repo_flag1=1
    for Index in "${__vender_tool_info[@]}"; do read -r -u9
    {
        __temp_logfile=$fifo_dir/$(echo "$Index" | sed 's/\//#/g')
        __flag=1
        {
            printf "[%s: %s]" "升级开始时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
            for bridge_fw in "${fw_bridge_files[@]}"; do
                echo "【command】bridge: hdparm --fwdownload-mode3 $bridge_fw --yes-i-know-what-i-am-doing --please-destroy-my-drive $Index"
                hdparm --fwdownload-mode3 "$bridge_fw" --yes-i-know-what-i-am-doing --please-destroy-my-drive "$Index"
            done
            echo "【command】hdparm --fwdownload-mode3 $fw_file --yes-i-know-what-i-am-doing --please-destroy-my-drive $Index"
            hdparm --fwdownload-mode3 "$fw_file" --yes-i-know-what-i-am-doing --please-destroy-my-drive "$Index" && __flag=0
            echo "Index=$Index, __flag=$__flag"
            printf "[%s: %s]" "升级结束时间"  "$(date +'%Y/%m/%d %H:%M:%S')"
        } >> "$__temp_logfile".log 2>&1
        mv "$__temp_logfile".log "$__temp_logfile=$__flag".log 
        echo 6 >&9
    } &
        sn_in_vender_tool[${#sn_in_vender_tool[*]}]=$(hdparm -I "$Index" | grep -i "Serial" | awk -F: '{print $2}' | awk '{$1=$1;print}')
    done
    raid_handler "$script_type"
}


# 铠侠
notool_hardware() {
    raid_handler "$script_type"
}


notool_version() {
    raid_handler "$script_type"
}


notool_update() {
    repo_flag1=1
    raid_handler "$script_type"
}

