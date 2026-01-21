#!/bin/bash

# ===================================================================
# Solana本地部署脚本
# 说明：部署程序到本地测试网络
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
    echo "Solana本地部署脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h          显示此帮助信息"
    echo "  --build, -b         部署前先构建程序"
    echo "  --reset             重置本地验证器"
    echo "  --program NAME      部署指定程序"
    echo "  --port PORT         指定本地验证器端口 (默认: 8899)"
    echo "  --no-validator      不自动启动本地验证器"
    echo ""
    echo "说明:"
    echo "  此脚本会自动启动本地验证器并部署程序"
    echo "  本地部署适合开发和测试环境"
}

# 检查是否在项目根目录
check_project_root() {
    if [ ! -f "Anchor.toml" ] && [ ! -f "Cargo.toml" ]; then
        print_color "red" "❌ 请在项目根目录下运行此脚本"
        print_color "blue" "提示：项目根目录应包含 Anchor.toml 或 Cargo.toml 文件"
        exit 1
    fi
}

# 检查本地验证器状态
check_validator_status() {
    if pgrep -f "solana-test-validator" > /dev/null; then
        print_color "green" "✅ 本地验证器正在运行"
        return 0
    else
        print_color "yellow" "⚠️ 本地验证器未运行"
        return 1
    fi
}

# 启动本地验证器
start_validator() {
    local port="$1"
    local reset_flag="$2"
    
    print_color "blue" "🚀 启动本地验证器..."
    
    # 检查验证器是否已经运行
    if check_validator_status; then
        if [ "$reset_flag" = true ]; then
            print_color "yellow" "🔄 重置本地验证器..."
            pkill -f "solana-test-validator"
            sleep 2
        else
            print_color "blue" "本地验证器已在运行，跳过启动步骤"
            return 0
        fi
    fi
    
    # 清理旧的测试账本数据（如果需要重置）
    if [ "$reset_flag" = true ] && [ -d "test-ledger" ]; then
        rm -rf test-ledger
        print_color "blue" "🧹 清理旧的测试账本数据"
    fi
    
    # 启动验证器命令
    local validator_cmd="solana-test-validator"
    
    # 添加端口参数
    if [ -n "$port" ]; then
        validator_cmd="$validator_cmd --rpc-port $port"
    fi
    
    # 添加其他参数
    validator_cmd="$validator_cmd --reset"
    validator_cmd="$validator_cmd --quiet"
    
    # 后台启动验证器
    print_color "blue" "启动命令: $validator_cmd"
    nohup $validator_cmd > "$LOG_DIR/validator.log" 2>&1 &
    
    # 等待验证器启动
    local max_wait=30
    local wait_count=0
    
    print_color "blue" "等待验证器启动..."
    while [ $wait_count -lt $max_wait ]; do
        if solana cluster-version >/dev/null 2>&1; then
            print_color "green" "✅ 验证器启动成功"
            return 0
        fi
        
        echo -n "."
        sleep 1
        wait_count=$((wait_count + 1))
    done
    
    echo ""
    print_color "red" "❌ 验证器启动超时"
    print_color "blue" "检查日志: $LOG_DIR/validator.log"
    return 1
}

# 配置网络为本地
configure_local_network() {
    local port="$1"
    local rpc_url="http://127.0.0.1:${port:-8899}"
    
    print_color "blue" "🌐 配置网络为本地..."
    
    if solana config set --url "$rpc_url"; then
        print_color "green" "✅ 网络配置成功: $rpc_url"
    else
        print_color "red" "❌ 网络配置失败"
        return 1
    fi
    
    # 验证网络连接
    print_color "blue" "🔍 验证网络连接..."
    if solana cluster-version >/dev/null 2>&1; then
        print_color "green" "✅ 网络连接正常"
    else
        print_color "red" "❌ 网络连接失败"
        return 1
    fi
}

# 检查和获取测试SOL
ensure_balance() {
    print_color "blue" "💰 检查钱包余额..."
    
    local current_balance=$(solana balance 2>/dev/null | awk '{print $1}')
    if [ $? -ne 0 ]; then
        print_color "red" "❌ 无法获取钱包余额"
        return 1
    fi
    
    print_color "blue" "当前余额: $current_balance SOL"
    
    # 检查余额是否足够
    local min_balance_int=$(echo "$MIN_BALANCE_SOL" | cut -d'.' -f1)
    local current_balance_int=$(echo "$current_balance" | cut -d'.' -f1)
    
    if [ "$current_balance_int" -lt "$min_balance_int" ]; then
        print_color "yellow" "⚠️ 余额不足，获取测试SOL..."
        
        if solana airdrop 10; then
            print_color "green" "✅ 测试SOL获取成功"
            local new_balance=$(solana balance 2>/dev/null | awk '{print $1}')
            print_color "blue" "新余额: $new_balance SOL"
        else
            print_color "red" "❌ 获取测试SOL失败"
            return 1
        fi
    else
        print_color "green" "✅ 余额充足"
    fi
}

# 构建程序
build_if_needed() {
    local build_flag="$1"
    
    if [ "$AUTO_BUILD_BEFORE_DEPLOY" = true ] || [ "$build_flag" = true ]; then
        print_color "blue" "🔨 构建程序..."
        
        if [ -f "Anchor.toml" ]; then
            if anchor build; then
                print_color "green" "✅ 程序构建成功"
            else
                print_color "red" "❌ 程序构建失败"
                return 1
            fi
        else
            if cargo build-sbf; then
                print_color "green" "✅ 程序构建成功"
            else
                print_color "red" "❌ 程序构建失败"
                return 1
            fi
        fi
    else
        print_color "yellow" "⏭️ 跳过程序构建"
    fi
}

# 部署程序
deploy_programs() {
    local specific_program="$1"
    
    print_color "blue" "🚀 部署程序到本地网络..."
    
    local start_time=$(date +%s)
    
    if [ -f "Anchor.toml" ]; then
        # 使用Anchor部署
        local deploy_cmd="anchor deploy --provider.cluster localnet"
        
        if [ -n "$specific_program" ]; then
            deploy_cmd="$deploy_cmd --program-name $specific_program"
        fi
        
        if eval $deploy_cmd; then
            print_color "green" "✅ Anchor部署成功"
        else
            print_color "red" "❌ Anchor部署失败"
            return 1
        fi
    else
        # 使用Solana CLI部署
        if [ -n "$specific_program" ]; then
            local program_file="./target/deploy/${specific_program}.so"
            if [ -f "$program_file" ]; then
                if solana program deploy "$program_file"; then
                    print_color "green" "✅ 程序部署成功: $specific_program"
                else
                    print_color "red" "❌ 程序部署失败: $specific_program"
                    return 1
                fi
            else
                print_color "red" "❌ 程序文件不存在: $program_file"
                return 1
            fi
        else
            # 部署所有程序
            local deploy_success=true
            for so_file in ./target/deploy/*.so; do
                if [ -f "$so_file" ]; then
                    local program_name=$(basename "$so_file" .so)
                    print_color "blue" "部署程序: $program_name"
                    
                    if solana program deploy "$so_file"; then
                        print_color "green" "✅ $program_name 部署成功"
                    else
                        print_color "red" "❌ $program_name 部署失败"
                        deploy_success=false
                    fi
                fi
            done
            
            if [ "$deploy_success" = false ]; then
                return 1
            fi
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    print_color "green" "🎉 部署完成，耗时: ${duration}秒"
}

# 验证部署
verify_deployment() {
    print_color "blue" "🔍 验证部署结果..."
    
    # 显示已部署的程序
    print_color "blue" "📋 已部署程序列表:"
    if solana program show --programs; then
        print_color "green" "✅ 程序列表获取成功"
    else
        print_color "yellow" "⚠️ 无法获取程序列表"
    fi
    
    # 检查程序账户
    if [ -d "./target/deploy" ]; then
        echo ""
        print_color "blue" "📊 程序信息:"
        for keypair_file in ./target/deploy/*-keypair.json; do
            if [ -f "$keypair_file" ]; then
                local program_id=$(solana address -k "$keypair_file" 2>/dev/null)
                if [ $? -eq 0 ]; then
                    local program_name=$(basename "$keypair_file" -keypair.json)
                    echo "  程序: $program_name"
                    echo "  ID: $program_id"
                    
                    # 检查程序账户信息
                    if solana account "$program_id" >/dev/null 2>&1; then
                        print_color "green" "  ✅ 程序账户存在"
                    else
                        print_color "red" "  ❌ 程序账户不存在"
                    fi
                    echo ""
                fi
            fi
        done
    fi
}

# 主部署流程
main_deploy() {
    local build_flag=false
    local reset_flag=false
    local specific_program=""
    local port=""
    local no_validator=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --build|-b)
                build_flag=true
                shift
                ;;
            --reset)
                reset_flag=true
                shift
                ;;
            --program)
                specific_program="$2"
                shift 2
                ;;
            --port)
                port="$2"
                shift 2
                ;;
            --no-validator)
                no_validator=true
                shift
                ;;
            *)
                print_color "red" "❌ 未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查项目根目录
    check_project_root
    
    # 确保日志目录存在
    mkdir -p "$LOG_DIR"
    
    print_color "blue" "🚀 开始本地部署流程..."
    print_color "blue" "项目: $PROJECT_NAME"
    if [ -n "$specific_program" ]; then
        print_color "blue" "程序: $specific_program"
    fi
    if [ -n "$port" ]; then
        print_color "blue" "端口: $port"
    fi
    echo ""
    
    # 启动本地验证器（如果需要）
    if [ "$no_validator" = false ]; then
        if ! start_validator "$port" "$reset_flag"; then
            exit 1
        fi
        echo ""
        
        # 配置网络
        if ! configure_local_network "$port"; then
            exit 1
        fi
        echo ""
    fi
    
    # 检查余额
    if ! ensure_balance; then
        exit 1
    fi
    echo ""
    
    # 构建程序
    if ! build_if_needed "$build_flag"; then
        exit 1
    fi
    echo ""
    
    # 部署程序
    if ! deploy_programs "$specific_program"; then
        exit 1
    fi
    echo ""
    
    # 验证部署
    verify_deployment
    
    echo ""
    print_color "green" "🎉 本地部署完成！"
    
    echo ""
    print_color "blue" "📝 接下来可以："
    echo "  1. 运行测试: ./development/06-test.sh"
    echo "  2. 监控程序: ./deployment/10-monitor.sh [PROGRAM_ID]"
    echo "  3. 部署到devnet: ./deployment/09-deploy-devnet.sh"
    
    echo ""
    print_color "blue" "💡 本地开发提示："
    echo "  - 本地验证器运行在: http://127.0.0.1:${port:-8899}"
    echo "  - 验证器日志: $LOG_DIR/validator.log"
    echo "  - 停止验证器: pkill -f solana-test-validator"
    echo "  - 重置验证器: $0 --reset"
}

# 执行主流程
main_deploy "$@"