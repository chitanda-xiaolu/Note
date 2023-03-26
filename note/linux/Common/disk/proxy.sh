VERSION=3.2
ARCCONF="$CURRENT_PATH/disk/utils/$(arch)/arcconf"
STORCLI64="$CURRENT_PATH/disk/utils/$(arch)/storcli64"
MNVCLI="$CURRENT_PATH/disk/utils/$(arch)/mnv_cli"
# 设置队列长度
[ "$script_type" = 'update' ] && threadTask=13 
grep -i "【阵列卡查询结果】" "$AUX_LOGGER" >/dev/null && aux_printf=false


_search_fw_file(){
    # 如果没有fw文件夹，直接退出，说明使用的旧方式
    if [ ! -d "$CURRENT_PATH"/fw ]; then
        fw_file=$CURRENT_PATH/$fw_file
        mapfile -t fw_bridge_files < <(grep <"$CURRENT_PATH/variable.sh" -iE "^fw_bridge_file" | sort | cut -d= -f2 | tr -d "'\"" | sed '/^\s*$/d' | xargs -I {} "$CURRENT_PATH"/{})
    else
        fw_file=$(_get_file "$CURRENT_PATH/fw")
        mapfile -t fw_bridge_files < <(find "$CURRENT_PATH"/fw -mindepth 2 -maxdepth 2 -type f | sort)
    fi
}


# 这里决定了库函数的命名必须是这俩种：1. nvme_${script_type} 2. ${tool}_${script_type}
_scheduler() {
    if [ "$script_type" = 'hardware' ]; then
        logger_info "Lib版本：$VERSION"
        logger_info "默认安装nvme-cli工具：rpm -ivh nvme*rpm --replacepkgs --force"
        rpm -ivh nvme*rpm --replacepkgs --force >>"$LOGGER_FILE" 2>&1 
    fi

    if [ "$script_type" == 'update' ]; then
        _search_fw_file
        [ -z "$fw_file" ] && repo_flag=1 && return
    fi

    logger_info "判断是否使用nvme-cli工具升级：nvme list | grep -iaE $HdModel && [ $tool != 'dsmart' ]"
    if nvme list | grep -iaE "$HdModel" >>"$LOGGER_FILE"; then
        if [ "$tool" = 'dsmart' ]; then
            lib_func=dsmart
        else
            lib_func=nvme
        fi
    else
        if [ "$tool" = 'dsmart' ]; then
            lib_func=hdparm
        else
            lib_func=$tool
        fi
    fi
    logger_info "使用的库函数：${lib_func}_${script_type}"
    "${lib_func}"_"${script_type}"
}
