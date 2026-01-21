#!/bin/bash

# ===================================================================
# Solana程序监控脚本
# 说明：监控Solana程序运行状态和日志
# ===================================================================

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_FILE="$SCRIPT_DIR/../config/project-config.sh"

# 加载配置文件
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "❌ 未找到配置文件: $CONFIG_FILE"
    exit 1
fi

# 颜色输出函数
print_color() {
    if [ "$ENABLE_COLORS" = true ]; then
        case $1 in
            "red")    echo -e "\033[31m$2\033[0m" ;;
            "green")  echo -e "\033[32m$2\033[0m" ;;
            "yellow") echo -e "\033[33m$2\033[0m" ;;
            "blue")   echo -e "\033[34m$2\033[0m" ;;
            "purple") echo -e "\033[35m$2\033[0m" ;;
            *)        echo "$2" ;;
        esac
    else
        echo "$2"
    fi
}

# 帮助信息
show_help() {
    echo "Solana程序监控脚本"
    echo ""
    echo "用法:"
    echo "  $0 [PROGRAM_ID] [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h          显示此帮助信息"
    echo "  --duration SECONDS  监控时长（秒），默认: $MONITOR_DURATION"
    echo "  --follow, -f        持续监控（不限时长）"
    echo "  --info              仅显示程序信息，不监控日志"
    echo "  --transactions      显示程序相关交易"
    echo "  --all               监控项目中所有程序"
    echo ""
    echo "说明:"
    echo "  此脚本用于监控Solana程序的运行状态和日志"
    echo "  如果不指定PROGRAM_ID，将尝试监控项目中的程序"
}

# 获取程序ID列表
get_program_ids() {
    local program_ids=()
    
    if [ -d "./target/deploy" ]; then
        for keypair_file in ./target/deploy/*-keypair.json; do
            if [ -f "$keypair_file" ]; then
                local program_id=$(solana address -k "$keypair_file" 2>/dev/null)
                if [ $? -eq 0 ] && [ -n "$program_id" ]; then
                    program_ids+=("$program_id")
                fi
            fi
        done
    fi
    
    echo "${program_ids[@]}"
}

# 显示程序信息
show_program_info() {
    local program_id="$1"
    
    print_color "blue" "📊 程序信息: $program_id"
    echo ""
    
    # 检查程序是否存在
    if ! solana account "$program_id" >/dev/null 2>&1; then
        print_color "red" "❌ 程序账户不存在或无法访问"
        return 1
    fi
    
    # 获取程序基本信息
    print_color "blue" "基本信息:"
    solana program show "$program_id" 2>/dev/null || {
        # 如果solana program show失败，使用account命令
        local account_info=$(solana account "$program_id" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "$account_info"
        else
            print_color "red" "❌ 无法获取程序信息"
            return 1
        fi
    }
    
    echo ""
    
    # 获取程序账户余额
    local balance=$(solana balance "$program_id" 2>/dev/null)
    if [ $? -eq 0 ]; then
        print_color "blue" "账户余额: $balance"
    fi
    
    # 生成浏览器链接
    local current_cluster=$(solana config get | grep "RPC URL" | awk '{print $3}')
    local cluster_param=""
    
    if [[ "$current_cluster" == *"devnet"* ]]; then
        cluster_param="?cluster=devnet"
    elif [[ "$current_cluster" == *"testnet"* ]]; then
        cluster_param="?cluster=testnet"
    elif [[ "$current_cluster" == *"localhost"* ]] || [[ "$current_cluster" == *"127.0.0.1"* ]]; then
        cluster_param="?cluster=custom&customUrl=http%3A%2F%2Flocalhost%3A8899"
    fi
    
    echo ""
    print_color "blue" "🔗 浏览器链接:"
    echo "https://explorer.solana.com/address/$program_id$cluster_param"
    
    return 0
}

# 显示程序相关交易
show_program_transactions() {
    local program_id="$1"
    local limit="${2:-10}"
    
    print_color "blue" "📋 最近的交易 (限制: $limit):"
    echo ""
    
    # 获取交易历史
    # 注意：这需要一个支持历史查询的RPC节点
    local signatures=$(solana transaction-history "$program_id" --limit "$limit" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$signatures" ]; then
        echo "$signatures"
    else
        print_color "yellow" "⚠️ 无法获取交易历史（可能需要支持历史查询的RPC节点）"
        print_color "blue" "提示：可以在浏览器中查看交易历史"
    fi
}

# 监控程序日志
monitor_program_logs() {
    local program_id="$1"
    local duration="$2"
    local follow="$3"
    
    print_color "blue" "📝 监控程序日志: $program_id"
    
    if [ "$follow" = true ]; then
        print_color "blue" "模式: 持续监控（按 Ctrl+C 停止）"
    else
        print_color "blue" "监控时长: ${duration}秒"
    fi
    
    echo ""
    print_color "blue" "开始时间: $(date)"
    echo "=================================================="
    echo ""
    
    # 构建监控命令
    local monitor_cmd="solana logs $program_id"
    
    if [ "$follow" = true ]; then
        # 持续监控
        eval $monitor_cmd
    else
        # 限时监控
        timeout "${duration}s" $monitor_cmd || {
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                # 超时是正常的
                echo ""
                echo "=================================================="
                print_color "blue" "监控结束: $(date)"
                print_color "green" "✅ 监控完成"
            else
                echo ""
                print_color "red" "❌ 监控异常退出"
                return 1
            fi
        }
    fi
}

# 监控所有项目程序
monitor_all_programs() {
    local duration="$1"
    local info_only="$2"
    
    local program_ids=($(get_program_ids))
    
    if [ ${#program_ids[@]} -eq 0 ]; then
        print_color "red" "❌ 未找到项目程序"
        print_color "blue" "提示：请确保程序已构建或已部署"
        return 1
    fi
    
    print_color "blue" "找到 ${#program_ids[@]} 个程序"
    echo ""
    
    for program_id in "${program_ids[@]}"; do
        # 获取程序名称
        local program_name=""
        for keypair_file in ./target/deploy/*-keypair.json; do
            if [ -f "$keypair_file" ]; then
                local id=$(solana address -k "$keypair_file" 2>/dev/null)
                if [ "$id" = "$program_id" ]; then
                    program_name=$(basename "$keypair_file" -keypair.json)
                    break
                fi
            fi
        done
        
        print_color "purple" "程序: ${program_name:-未知} ($program_id)"
        echo ""
        
        show_program_info "$program_id"
        
        if [ "$info_only" != true ]; then
            echo ""
            echo "=================================================="
            echo ""
            
            # 为了避免同时监控多个程序，询问用户
            print_color "yellow" "是否监控此程序的日志? (y/N)"
            read -r response
            
            if [[ "$response" =~ ^[Yy]$ ]]; then
                monitor_program_logs "$program_id" "$duration" false
            fi
        fi
        
        echo ""
        echo "=================================================="
        echo ""
    done
}

# 检查网络连接
check_network_connection() {
    print_color "blue" "🌐 检查网络连接..."
    
    if solana cluster-version >/dev/null 2>&1; then
        local cluster_version=$(solana cluster-version)
        local rpc_url=$(solana config get | grep "RPC URL" | awk '{print $3}')
        
        print_color "green" "✅ 网络连接正常"
        print_color "blue" "RPC端点: $rpc_url"
        print_color "blue" "集群版本: $cluster_version"
        return 0
    else
        print_color "red" "❌ 网络连接失败"
        print_color "blue" "请检查："
        echo "  1. 网络配置是否正确"
        echo "  2. RPC端点是否可访问"
        echo "  3. 是否有网络连接"
        return 1
    fi
}

# 保存监控日志
save_monitoring_log() {
    local program_id="$1"
    local log_content="$2"
    
    local log_file="$LOG_DIR/monitor-${program_id}-$(date +%Y%m%d-%H%M%S).log"
    
    # 确保日志目录存在
    mkdir -p "$LOG_DIR"
    
    echo "$log_content" > "$log_file"
    
    print_color "green" "✅ 监控日志已保存: $log_file"
}

# 主监控流程
main_monitor() {
    local program_id=""
    local duration="$MONITOR_DURATION"
    local follow=false
    local info_only=false
    local show_transactions=false
    local monitor_all=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --duration)
                duration="$2"
                shift 2
                ;;
            --follow|-f)
                follow=true
                shift
                ;;
            --info)
                info_only=true
                shift
                ;;
            --transactions)
                show_transactions=true
                shift
                ;;
            --all)
                monitor_all=true
                shift
                ;;
            -*)
                print_color "red" "❌ 未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                # 第一个非选项参数是program_id
                if [ -z "$program_id" ]; then
                    program_id="$1"
                fi
                shift
                ;;
        esac
    done
    
    print_color "blue" "🚀 开始监控Solana程序..."
    echo ""
    
    # 检查网络连接
    if ! check_network_connection; then
        exit 1
    fi
    echo ""
    
    # 如果指定监控所有程序
    if [ "$monitor_all" = true ]; then
        monitor_all_programs "$duration" "$info_only"
        exit 0
    fi
    
    # 如果没有指定program_id，尝试从项目中获取
    if [ -z "$program_id" ]; then
        local program_ids=($(get_program_ids))
        
        if [ ${#program_ids[@]} -eq 0 ]; then
            print_color "red" "❌ 未指定程序ID且未找到项目程序"
            print_color "blue" "用法: $0 [PROGRAM_ID]"
            print_color "blue" "或使用 --all 选项监控所有项目程序"
            exit 1
        elif [ ${#program_ids[@]} -eq 1 ]; then
            # 只有一个程序，自动使用
            program_id="${program_ids[0]}"
            print_color "blue" "使用项目程序: $program_id"
            echo ""
        else
            # 多个程序，让用户选择
            print_color "blue" "找到 ${#program_ids[@]} 个程序，请选择："
            echo ""
            
            local i=1
            for id in "${program_ids[@]}"; do
                # 获取程序名称
                local program_name=""
                for keypair_file in ./target/deploy/*-keypair.json; do
                    if [ -f "$keypair_file" ]; then
                        local pid=$(solana address -k "$keypair_file" 2>/dev/null)
                        if [ "$pid" = "$id" ]; then
                            program_name=$(basename "$keypair_file" -keypair.json)
                            break
                        fi
                    fi
                done
                
                echo "  $i) ${program_name:-未知} ($id)"
                i=$((i + 1))
            done
            
            echo ""
            echo -n "请输入序号 (1-${#program_ids[@]}): "
            read -r choice
            
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#program_ids[@]} ]; then
                program_id="${program_ids[$((choice - 1))]}"
                print_color "green" "✅ 已选择: $program_id"
                echo ""
            else
                print_color "red" "❌ 无效的选择"
                exit 1
            fi
        fi
    fi
    
    # 显示程序信息
    if ! show_program_info "$program_id"; then
        exit 1
    fi
    echo ""
    
    # 显示交易历史
    if [ "$show_transactions" = true ]; then
        show_program_transactions "$program_id" 10
        echo ""
    fi
    
    # 监控程序日志
    if [ "$info_only" != true ]; then
        monitor_program_logs "$program_id" "$duration" "$follow"
    fi
    
    echo ""
    print_color "green" "🎉 监控完成！"
    
    echo ""
    print_color "blue" "💡 有用的命令:"
    echo "  查看程序信息: solana program show $program_id"
    echo "  查看账户信息: solana account $program_id"
    echo "  持续监控日志: $0 $program_id --follow"
}

# 执行主流程
main_monitor "$@"
