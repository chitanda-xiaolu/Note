VERSION=3.2
LSPCI="$CURRENT_PATH/card/utils/$(arch)/lspci"
SETPCI="$CURRENT_PATH/card/utils/$(arch)/setpci"
[ -n "${ids[*]}" ] && pci_ids_str=$(echo "${ids[*]}" | tr ' ' '|' | tr ',' ' ') && logger_info "PCIID的正则匹配字符串: $pci_ids_str"


_install_elxocm_tool() {
    rhel_major_version=$(awk -F'.' '{print $1}' /etc/redhat-release | awk '{print $NF}')
    if [[ "$rhel_major_version" -eq 7 ]]; then
        OS_VER="rhel-7"
    elif [[ "$rhel_major_version" -eq 8 ]]; then
        OS_VER="rhel-8"
    elif [[ "$rhel_major_version" -eq 9 ]]; then
        OS_VER="rhel-9"
    else
        logger_error "This is not a supported version of $RHEL_OS_STR."
        logger_error "Aborting installation."
        return
    fi
    logger_info "rpm -ivh --replacepkgs --force ./elxocmcore/$(arch)/${OS_VER}/*.rpm"
    rpm -ivh --replacepkgs --force ./elxocmcore/"$(arch)"/"${OS_VER}"/*.rpm >> "$LOGGER_FILE" 2>&1
    hbacmd version >/dev/null 2>&1 || cp /opt/emulex/ocmanager/bin/hbacmd /usr/bin/hbacmd >/dev/null 2>&1
}


_install_tool() {
    [ "$script_type" = 'hardware' ] || return
    cd "$CURRENT_PATH" || exit

    if [ "$tool" = 'elxocm' ]; then
        _install_elxocm_tool
        hbacmd version >/dev/null 2>&1 || logger_err "Tool install Failed! "

    elif [ "$tool" = 'QConCLI' ]; then
        logger_info "rpm -ivh QCon*rpm --replacepkgs --force"
        rpm -ivh QCon*rpm --replacepkgs --force >> "$LOGGER_FILE" 2>&1
        qaucli -i >/dev/null 2>&1 || logger_err "Tool install Failed! "

    elif [ "$tool" = 'sfc' ]; then
        logger_info "rpm -ivh sf*rpm --replacepkgs --force"
        rpm -ivh sf*rpm --replacepkgs --force >> "$LOGGER_FILE" 2>&1
        sfupdate >/dev/null 2>&1 || logger_err "Tool install Failed! "

    elif [ "$tool" = 'eeupdate64e' ]; then
        logger_info "cp -f $CURRENT_PATH/iqvlinux_$(uname -r).ko /lib/modules/$(uname -r)/kernel/drivers/net/iqvlinux.ko"
        \cp -f "$CURRENT_PATH"/iqvlinux_"$(uname -r)".ko /lib/modules/"$(uname -r)"/kernel/drivers/net/iqvlinux.ko 2>/dev/null
        logger_info "depmod"
        depmod >>"$LOGGER_FILE" 2>&1
        logger_info "modprobe iqvlinux"
        modprobe "iqvlinux" >>"$LOGGER_FILE" 2>&1

    elif [ "$tool" = 'mft' ]; then
        logger_info "rpm -ivh mft*rpm --replacepkgs --force"
        rpm -ivh mft*rpm --replacepkgs --force >> "$LOGGER_FILE" 2>&1
        __rpm_pkg=$(find "$CURRENT_PATH" -maxdepth 1 -mindepth 1 -name '*kernel-mft*rpm' | grep "$(uname -r|tr '-' '_')")
        logger_info "rpm -ivh $__rpm_pkg --replacepkgs --force"
        rpm -ivh "$__rpm_pkg" --replacepkgs --force >> "$LOGGER_FILE" 2>&1
        mst start >/dev/null 2>&1
        mst status >/dev/null 2>&1 || logger_err "Tool install Failed! "

    fi
}


_ethtool() {
    local line=$1
    __device=$(find /sys/bus/pci/devices/"$line"/net -maxdepth 1 -mindepth 1 -printf "%f\n" 2>/dev/null | head -n1 | awk '{print $1}')
    if [ -z "$__device" ]; then
        logger_error "PCI匹配但设备不存在！"
        logger_tipinfo "Please install the driver before upgrading the firmware!"
    else
        __version=$(ethtool -i "$__device" | grep -i "firmware-version" | cut -d: -f2 | awk -F '/pkg' '{print $NF}' | awk '{print $1}' | sed 's/,//g' | sed 's/]//g')
        logger_info "$__device: $__version"
        echo "$__version" >>"$CURRENT_PATH"/version.txt
    fi
}


_lom_check() {
    local __line=$1
    local card='B2'
    echo "$__line" | grep -E ":01:|:04:|:1:|:4:" >/dev/null && logger_warn "过滤掉板载360T" && return 1
    $LSPCI -s "$__line" -vv | grep -i 'Physical slot: 9' >/dev/null && card='Flom'
    $LSPCI -s "$__line" -vv | grep -iE "Physical Slot: 11|Physical Slot: 25|Physical Slot: 55" >/dev/null && card='Slom'
    [ "$card" != "$lom" ] && logger_warn "过滤掉与预设值不同的卡" && return 1
    return 0
}


_port_num_check() {
    local __line=$1
    __port_num=$($LSPCI -Dnn 2>/dev/null | grep -c -i "$(echo $__line | cut -d. -f1)")
    [ "$port_num" -ne "$__port_num" ] && logger_warn "过滤掉与预设的网口个数不同的卡" && return 1
}


_id_match() {
    for __id in "${ids[@]}"; do
        __device_id=${__id:0:4}:${__id:5:4}
        __sub_device_id=${__id:15:4}${__id:10:4}
        mapfile -t __id_list < <($LSPCI -Dnn 2>/dev/null | grep -i "$__device_id" | cut -d: -f1-2 | xargs -I {} echo {}: | sort -u | sed '/^\s*$/d')
        for __bus_id in "${__id_list[@]}"; do
            __line=$($LSPCI -Dnn 2>/dev/null | grep -ioE "^${__bus_id}00.0" || $LSPCI -Dnn 2>/dev/null | grep -iE "^${__bus_id}" | awk '{print $1}' | sed -n 1p)
            __subid=$($SETPCI -s "$__line" 2c.l | tr '[:lower:]' '[:upper:]')
            if [ "$__subid" = "$__sub_device_id" ]; then  
                logger_info "匹配检查：$__line"
                [ -z "$lom" ] || _lom_check "$__line" || continue
                [ -z "$port_num" ] || _port_num_check "$__line" || continue
                logger_info "通过匹配！"
                match_lines[${#match_lines[*]}]=$__line
            fi
        done
    done

}


_lib_func() {
    _id_match
    local sub_lib_func=$1
    [ -z "${match_lines[*]}" ] && repo_flag=1
    [ "$script_type" = 'hardware' ] && return
    for line in "${match_lines[@]}"; do
        logger_info "$sub_lib_func"
        $sub_lib_func "$line"
    done
}


# schedule_dict['nvmupdate64e']="hardware=_lib_func version=nvmupdate64e_version update=intel_update_nvmupdate64e"
# schedule_dict['s_nvmupdate64e']="hardware=s_nvmupdate64e_hardware version=s_nvmupdate64e_version update=s_intel_update_nvmupdate64e"
# 调度命令在库函数定义之前注册
_scheduler() {
    local lib_func
    local sub_lib_func
    [ "$script_type" = 'hardware' ] && logger_info "Lib版本：$VERSION"
    _install_tool
    schedule_cmd=${schedule_dict["$tool"]}
    [ -z "$schedule_cmd" ] && logger_error "未获取到调度命令！" && return
    for param in $schedule_cmd; do
        [[ $param =~ $script_type= ]] && __call_chain=${param#*=}
    done
    [ -z "$__call_chain" ] && logger_error "调度命令：$schedule_cmd，未获取到库函数！" && return
    if [[ $__call_chain =~ _lib_func: ]]; then
        lib_func=_lib_func
        sub_lib_func=$(echo "$__call_chain" | cut -d: -f2)
    else
        lib_func=$__call_chain
        sub_lib_func=""
    fi
    logger_info "调度命令：$schedule_cmd，库函数：$lib_func $sub_lib_func"
    $lib_func "$sub_lib_func"
}
