#!/usr/bin/env bash

cd "$(dirname "$0")" || exit
CURRENT_PATH=$(pwd)
chmod 777 -R "$CURRENT_PATH"
# 库函数调度关系字典
# shellcheck disable=SC2034  # Don't warn about unused variables schedule_dict
declare -A schedule_dict


# shellcheck disable=SC2317  # Don't warn about unreachable commands in _get_file
_get_file() { 
    local path=$1
    local regex=$2
    local unregex=$3
    local result
    if [ -z "$unregex" ]; then
        result=$(find "$path" -mindepth 1 -maxdepth 1 -type f | grep -iE "$regex")
    else
        result=$(find "$path" -mindepth 1 -maxdepth 1 -type f | grep -iE "$regex" | grep -ivE "$unregex")
    fi
    
    if [ -z "$result" ] || [ "$(echo "$result" | wc -l)" -ne 1 ]; then
        logger_error "can not get a file from $path by regex $regex"
        return
    else
        echo "$result"
    fi
}


_fifo_init() {
    [ -z "$threadTask" ] && return
    fifo_dir=$CURRENT_PATH/fifo_log
    [ -d "$fifo_dir" ] && rm -rf "$fifo_dir" 
    mkdir "$fifo_dir"
    __fifofile="$CURRENT_PATH/$$.fifo"
    rm -f "$__fifofile"
    mkfifo "$__fifofile"
    exec 9<>"$__fifofile"
    seq "$threadTask" >&9
}


_fifo_end() {
    [ -z "$threadTask" ] && return
    wait 
    exec 9>&- # 关闭管道
    rm -f "$__fifofile"  
    fifo_logs=$(find "$fifo_dir" -maxdepth 1 -type f | grep ".log")
    [ -z "$fifo_logs" ] && return
    logger_info "输出并行子进程的日志"
    cat "$fifo_dir"/* >> "$LOGGER_FILE"
    logger_info "子进程的结果"
    echo "$fifo_logs" | grep "=1.log" > /dev/null && repo_flag=1
}


_jump_to() {
    __func=$2
    shift 2
    $__func "$@"
}


_log_init() {
    source "$CURRENT_PATH"/shell-logger
    [ ! -d "$CURRENT_PATH"/log ] && mkdir "$CURRENT_PATH"/log
    LOGGER_FILE="$CURRENT_PATH/log/fw.log"
    AUX_LOGGER="$CURRENT_PATH/log/aux_info.log"
    touch {"$LOGGER_FILE","$AUX_LOGGER"}
}


_flag_init() {
    # 初始化多个标记值，是唯一可用于判断程序成功或失败的属性
    flags=("repo_flag" "repo_flag1" "repo_flag2" "repo_flag3" "repo_flag4" "repo_flag5")
    read -r repo_flag repo_flag1 repo_flag2 repo_flag3 repo_flag4 repo_flag5 <<<"0 0 0 0 0 0"
}


_scene() {
    SCENE="yongfu"
    if [ -f "/run/REPO/tools/repoinstall_update.py" ]; then
        SCENE="shengchan"
        grep "7.3" >/dev/null </etc/redhat-release && SCENE+="G3"
        grep -E "8.2|8.3" >/dev/null </etc/redhat-release && SCENE+="G5"
        grep "9.0" >/dev/null </etc/redhat-release && SCENE+="G6"

        [ -f "/run/REPO/tools/callback" ] && SCENE+='_Callback'
    fi
    logger_info "$script_type start"
    logger_info "当前场景：$SCENE"
    logger_info "当前路径：$CURRENT_PATH"
}



_source() {
    source "$CURRENT_PATH"/variable.sh
    source "$CURRENT_PATH"/"${lib_type}"/proxy.sh
    source "$CURRENT_PATH"/"${lib_type}"/custom_func.sh
}

_txt_handler() {
    if [ "$1" = 'start' ]; then
        txt_files_before=$(find "$CURRENT_PATH" -mindepth 1 -maxdepth 1 -name '*txt')
    elif  [ "$1" = 'end' ]; then
        mapfile -t txt_files_after < <(find "$CURRENT_PATH" -mindepth 1 -maxdepth 1 -name '*txt')
        for txt in "${txt_files_after[@]}"; do 
            if echo "$txt_files_before" | grep -v "$txt" > /dev/null; then
                logger_info "rm -f $txt"
                rm -f "$txt"
            fi
        done
    fi
}


_repo_end() {
    if [ "$script_type" = 'version' ]; then 
        # 硬盘厂商工具获取的版本前后可能有空格，xargs去空格后再去重一次
        if [ ! -f  "$CURRENT_PATH"/version.txt ]; then
          logger_err "版本获取失败，可能原因：驱动未加载或不兼容"
          echo "=*"
        else
          __version=$(sort -u <"$CURRENT_PATH"/version.txt | awk '{$1=$1;print}' | sort -u | xargs | sed 's/[[:space:]]/##/g')
          echo "=$__version*"
          logger_info "当前版本号: $__version"
        fi
    else
        # 存在flag的值为1，那么返回False
        check_flag=$(for i in "${flags[@]}"; do [ "${!i}" -eq 1 ] && printf "%s=%s " "$i" "${!i}"; done)
        [ "$script_type" = "hardware" ] && __echo="HARDWARE" || __echo="INSTALLED"
        if [ -z "$check_flag" ]; then
          echo "${__echo}:TRUE"
        else
          logger_error "check_flag: $check_flag"
          echo "${__echo}:FALSE"
        fi 
    fi
    _txt_handler 'end'
    logger_info "$script_type end"
}


repo_stage() {
    _log_init
    _flag_init
    _scene
    _txt_handler 'start'
    _source
    _fifo_init
    _jump_to 'proxy' '_scheduler'
    _fifo_end
    _repo_end
}


# 命令行入口 
case $1 in 
-h|--hardware) 
    script_type='hardware'
    repo_stage
    exit 
    ;; 
-v|--version) 
    script_type='version'
    repo_stage
    exit 
    ;; 
-u|--update) 
    script_type='update'
    repo_stage
    exit  
    ;; 
-g|--model) 
    _log_init
    source "$CURRENT_PATH"/disk/proxy.sh
    source "$CURRENT_PATH"/disk/custom_func.sh
    _jump_to 'custom_func' 'raid_handler' 'get_model'
    exit 
    ;; 
*) 
    echo "unsupport option!" 
    exit 
    ;; 
esac 
