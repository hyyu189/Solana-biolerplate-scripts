#!/bin/bash

# ===================================================================
# Solana Devnet部署脚本
# 说明：部署程序到Solana开发测试网络
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
    echo "Solana Devnet部署脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h          显示此帮助信息"
    echo "  --build, -b         部署前先构建程序"
    echo "  --program NAME      部署指定程序"
    echo "  --skip-balance      跳过余额检查"
    echo "  --skip-confirm      跳过部署确认"
    echo "  --upgrade           升级现有程序"
    echo ""
    echo "说明:"
    echo "  此脚本会将程序部署到Solana devnet测试网络"
    echo "  部署到devnet需要测试SOL，可以使用 ./setup/02-setup-wallet.sh --airdrop 获取"
}

# 检查是否在项目根目录
check_project_root() {
    if [ ! -f "Anchor.toml" ] && [ ! -f "Cargo.toml" ]; then
        print_color "red" "❌ 请在项目根目录下运行此脚本"
        print_color "blue" "提示：项目根目录应包含 Anchor.toml 或 Cargo.toml 文件"
        exit 1
    fi
}

# 配置网络为devnet
configure_devnet() {
    print_color "blue" "🌐 配置网络为devnet..."
    
    if solana config set --url "$DEVNET_RPC"; then
        print_color "green" "✅ 网络配置成功: devnet"
        print_color "blue" "RPC端点: $DEVNET_RPC"
    else
        print_color "red" "❌ 网络配置失败"
        return 1
    fi
    
    # 验证网络连接
    print_color "blue" "🔍 验证网络连接..."
    if solana cluster-version >/dev/null 2>&1; then
        local cluster_version=$(solana cluster-version)
        print_color "green" "✅ 网络连接正常"
        print_color "blue" "集群版本: $cluster_version"
    else
        print_color "red" "❌ 网络连接失败"
        return 1
    fi
}

# 检查钱包余额
check_balance() {
    local skip_balance="$1"
    
    if [ "$skip_balance" = true ]; then
        print_color "yellow" "⏭️ 跳过余额检查"
        return 0
    fi
    
    print_color "blue" "💰 检查钱包余额..."
    
    local wallet_address=$(solana address 2>/dev/null)
    if [ $? -ne 0 ]; then
        print_color "red" "❌ 无法获取钱包地址"
        return 1
    fi
    
    print_color "blue" "钱包地址: $wallet_address"
    
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
        print_color "red" "❌ 余额不足"
        print_color "yellow" "最低需要: $MIN_BALANCE_SOL SOL"
        print_color "yellow" "当前余额: $current_balance SOL"
        echo ""
        print_color "blue" "💡 获取测试SOL:"
        echo "  运行: ../setup/02-setup-wallet.sh --airdrop"
        echo "  或访问: https://faucet.solana.com"
        return 1
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

# 确认部署
confirm_deployment() {
    local skip_confirm="$1"
    local program_name="$2"
    
    if [ "$skip_confirm" = true ]; then
        return 0
    fi
    
    echo ""
    print_color "yellow" "⚠️  即将部署到 DEVNET 测试网络"
    echo ""
    print_color "blue" "部署信息:"
    echo "  网络: devnet"
    echo "  RPC: $DEVNET_RPC"
    if [ -n "$program_name" ]; then
        echo "  程序: $program_name"
    else
        echo "  程序: 所有程序"
    fi
    echo "  钱包: $(solana address)"
    echo "  余额: $(solana balance)"
    echo ""
    
    # 估算费用
    if [ -d "./target/deploy" ]; then
        local total_size=0
        for so_file in ./target/deploy/*.so; do
            if [ -f "$so_file" ]; then
                local size=$(stat -f%z "$so_file" 2>/dev/null || stat -c%s "$so_file" 2>/dev/null)
                total_size=$((total_size + size))
            fi
        done
        
        if [ $total_size -gt 0 ]; then
            local size_kb=$((total_size / 1024))
            print_color "blue" "  估计大小: $size_kb KB"
            # 粗略估算：每KB约0.000005 SOL
            local estimated_cost=$(echo "scale=6; $size_kb * 0.000005" | bc 2>/dev/null || echo "0.1")
            print_color "blue" "  估计费用: ~$estimated_cost SOL"
        fi
    fi
    
    echo ""
    print_color "yellow" "是否继续部署? (yes/no)"
    read -r response
    
    if [[ "$response" != "yes" ]]; then
        print_color "yellow" "❌ 已取消部署"
        exit 0
    fi
}

# 部署程序
deploy_programs() {
    local specific_program="$1"
    local is_upgrade="$2"
    
    print_color "blue" "🚀 部署程序到devnet..."
    
    local start_time=$(date +%s)
    
    if [ -f "Anchor.toml" ]; then
        # 使用Anchor部署
        local deploy_cmd="anchor deploy --provider.cluster devnet"
        
        if [ -n "$specific_program" ]; then
            deploy_cmd="$deploy_cmd --program-name $specific_program"
        fi
        
        print_color "blue" "执行命令: $deploy_cmd"
        
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
            local keypair_file="./target/deploy/${specific_program}-keypair.json"
            
            if [ ! -f "$program_file" ]; then
                print_color "red" "❌ 程序文件不存在: $program_file"
                return 1
            fi
            
            if [ "$is_upgrade" = true ] && [ -f "$keypair_file" ]; then
                # 升级现有程序
                local program_id=$(solana address -k "$keypair_file")
                print_color "blue" "升级程序: $specific_program ($program_id)"
                
                if solana program deploy "$program_file" --program-id "$program_id"; then
                    print_color "green" "✅ 程序升级成功"
                else
                    print_color "red" "❌ 程序升级失败"
                    return 1
                fi
            else
                # 部署新程序
                if solana program deploy "$program_file"; then
                    print_color "green" "✅ 程序部署成功: $specific_program"
                else
                    print_color "red" "❌ 程序部署失败: $specific_program"
                    return 1
                fi
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
    
    # 检查程序账户
    if [ -d "./target/deploy" ]; then
        echo ""
        print_color "blue" "📊 已部署程序:"
        
        for keypair_file in ./target/deploy/*-keypair.json; do
            if [ -f "$keypair_file" ]; then
                local program_id=$(solana address -k "$keypair_file" 2>/dev/null)
                if [ $? -eq 0 ]; then
                    local program_name=$(basename "$keypair_file" -keypair.json)
                    echo ""
                    print_color "purple" "程序: $program_name"
                    echo "  ID: $program_id"
                    
                    # 检查程序账户信息
                    if solana account "$program_id" >/dev/null 2>&1; then
                        print_color "green" "  ✅ 程序账户存在"
                        
                        # 获取程序信息
                        local account_info=$(solana program show "$program_id" 2>/dev/null)
                        if [ $? -eq 0 ]; then
                            echo "  程序详情:"
                            echo "$account_info" | grep -E "ProgramData|Authority|Last Deployed" | sed 's/^/    /'
                        fi
                    else
                        print_color "red" "  ❌ 程序账户不存在"
                    fi
                    
                    # 生成浏览器链接
                    print_color "blue" "  🔗 浏览器: https://explorer.solana.com/address/$program_id?cluster=devnet"
                fi
            fi
        done
    fi
}

# 保存部署记录
save_deployment_record() {
    print_color "blue" "📝 保存部署记录..."
    
    local record_file="$LOG_DIR/deployments/devnet-$(date +%Y%m%d-%H%M%S).txt"
    
    # 确保目录存在
    mkdir -p "$LOG_DIR/deployments"
    
    # 生成部署记录
    {
        echo "==============================================="
        echo "Solana Devnet部署记录"
        echo "==============================================="
        echo "部署时间: $(date)"
        echo "项目名称: $PROJECT_NAME"
        echo "网络: devnet"
        echo "RPC端点: $DEVNET_RPC"
        echo "钱包地址: $(solana address)"
        echo ""
        echo "已部署程序:"
        
        if [ -d "./target/deploy" ]; then
            for keypair_file in ./target/deploy/*-keypair.json; do
                if [ -f "$keypair_file" ]; then
                    local program_id=$(solana address -k "$keypair_file" 2>/dev/null)
                    local program_name=$(basename "$keypair_file" -keypair.json)
                    echo "  - $program_name: $program_id"
                fi
            done
        fi
        
        echo ""
        echo "浏览器链接:"
        if [ -d "./target/deploy" ]; then
            for keypair_file in ./target/deploy/*-keypair.json; do
                if [ -f "$keypair_file" ]; then
                    local program_id=$(solana address -k "$keypair_file" 2>/dev/null)
                    local program_name=$(basename "$keypair_file" -keypair.json)
                    echo "  $program_name: https://explorer.solana.com/address/$program_id?cluster=devnet"
                fi
            done
        fi
        
    } > "$record_file"
    
    print_color "green" "✅ 部署记录已保存: $record_file"
}

# 主部署流程
main_deploy() {
    local build_flag=false
    local specific_program=""
    local skip_balance=false
    local skip_confirm=false
    local is_upgrade=false
    
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
            --program)
                specific_program="$2"
                shift 2
                ;;
            --skip-balance)
                skip_balance=true
                shift
                ;;
            --skip-confirm)
                skip_confirm=true
                shift
                ;;
            --upgrade)
                is_upgrade=true
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
    
    print_color "blue" "🚀 开始Devnet部署流程..."
    print_color "blue" "项目: $PROJECT_NAME"
    if [ -n "$specific_program" ]; then
        print_color "blue" "程序: $specific_program"
    fi
    if [ "$is_upgrade" = true ]; then
        print_color "blue" "模式: 升级"
    fi
    echo ""
    
    # 配置网络
    if ! configure_devnet; then
        exit 1
    fi
    echo ""
    
    # 检查余额
    if ! check_balance "$skip_balance"; then
        exit 1
    fi
    echo ""
    
    # 构建程序
    if ! build_if_needed "$build_flag"; then
        exit 1
    fi
    echo ""
    
    # 确认部署
    confirm_deployment "$skip_confirm" "$specific_program"
    
    # 部署程序
    if ! deploy_programs "$specific_program" "$is_upgrade"; then
        exit 1
    fi
    echo ""
    
    # 验证部署
    verify_deployment
    echo ""
    
    # 保存部署记录
    save_deployment_record
    
    echo ""
    print_color "green" "🎉 Devnet部署完成！"
    
    echo ""
    print_color "blue" "📝 接下来可以："
    echo "  1. 监控程序: ../deployment/10-monitor.sh [PROGRAM_ID]"
    echo "  2. 运行测试: ../development/06-test.sh"
    echo "  3. 查看部署记录: cat $LOG_DIR/deployments/*.txt"
    
    echo ""
    print_color "blue" "🌐 有用的链接:"
    echo "  - Solana浏览器: https://explorer.solana.com/?cluster=devnet"
    echo "  - 获取测试SOL: https://faucet.solana.com"
    echo "  - Devnet状态: https://status.solana.com"
}

# 执行主流程
main_deploy "$@"
