#!/bin/bash

# ===================================================================
# Solana钱包设置脚本
# 说明：设置开发钱包并配置网络环境
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
    echo "Solana钱包设置脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h      显示此帮助信息"
    echo "  --new, -n       创建新钱包（会备份现有钱包）"
    echo "  --import FILE   导入现有钱包文件"
    echo "  --network NET   设置网络 (localnet/devnet/testnet/mainnet-beta)"
    echo "  --airdrop       获取测试SOL（仅限测试网络）"
    echo "  --check, -c     仅检查钱包状态"
    echo ""
    echo "说明:"
    echo "  此脚本会设置Solana开发钱包并配置网络环境"
    echo "  默认创建开发钱包并设置为devnet网络"
}

# 检查Solana CLI是否安装
check_solana_cli() {
    if ! command -v solana &> /dev/null; then
        print_color "red" "❌ Solana CLI未安装"
        print_color "blue" "请先运行: ./setup/01-install-tools.sh"
        exit 1
    fi
}

# 检查钱包状态
check_wallet_status() {
    print_color "blue" "🔍 检查钱包状态..."
    echo ""
    
    # 检查配置
    print_color "blue" "📋 当前Solana配置:"
    solana config get
    echo ""
    
    # 检查钱包文件
    if [ -f "$WALLET_PATH" ]; then
        print_color "green" "✅ 钱包文件存在: $WALLET_PATH"
        
        # 显示钱包地址
        local wallet_address=$(solana address 2>/dev/null)
        if [ $? -eq 0 ]; then
            print_color "green" "📍 钱包地址: $wallet_address"
        else
            print_color "red" "❌ 无法读取钱包地址"
        fi
        
        # 检查余额
        local balance=$(solana balance 2>/dev/null)
        if [ $? -eq 0 ]; then
            print_color "green" "💰 当前余额: $balance"
        else
            print_color "yellow" "⚠️ 无法获取余额信息"
        fi
        
    else
        print_color "yellow" "⚠️ 钱包文件不存在: $WALLET_PATH"
    fi
    
    # 检查网络连接
    print_color "blue" "🌐 检查网络连接..."
    if solana cluster-version >/dev/null 2>&1; then
        print_color "green" "✅ 网络连接正常"
    else
        print_color "red" "❌ 网络连接失败"
    fi
}

# 备份现有钱包
backup_wallet() {
    if [ -f "$WALLET_PATH" ]; then
        local backup_dir="$BACKUP_DIR/wallets"
        mkdir -p "$backup_dir"
        
        local timestamp=$(date +%Y%m%d-%H%M%S)
        local backup_file="$backup_dir/wallet-backup-$timestamp.json"
        
        cp "$WALLET_PATH" "$backup_file"
        print_color "green" "✅ 钱包已备份到: $backup_file"
        
        # 显示备份钱包地址
        local backup_address=$(solana address -k "$backup_file" 2>/dev/null)
        if [ $? -eq 0 ]; then
            print_color "blue" "📍 备份钱包地址: $backup_address"
        fi
    fi
}

# 创建新钱包
create_new_wallet() {
    print_color "blue" "🔑 创建新钱包..."
    
    # 备份现有钱包（如果存在）
    if [ -f "$WALLET_PATH" ]; then
        print_color "yellow" "⚠️ 发现现有钱包，正在备份..."
        backup_wallet
    fi
    
    # 确保钱包目录存在
    local wallet_dir=$(dirname "$WALLET_PATH")
    mkdir -p "$wallet_dir"
    
    # 创建新钱包
    print_color "blue" "正在生成新的密钥对..."
    if solana-keygen new --outfile "$WALLET_PATH" --no-bip39-passphrase; then
        print_color "green" "✅ 新钱包创建成功"
        
        # 显示钱包地址
        local wallet_address=$(solana address)
        print_color "green" "📍 钱包地址: $wallet_address"
        
        # 设置为默认钱包
        solana config set --keypair "$WALLET_PATH"
        print_color "green" "✅ 已设置为默认钱包"
        
        # 安全提示
        echo ""
        print_color "yellow" "🔒 安全提示:"
        echo "  1. 请妥善保管钱包文件: $WALLET_PATH"
        echo "  2. 定期备份钱包文件"
        echo "  3. 不要与他人分享钱包文件"
        echo "  4. 在生产环境中使用硬件钱包"
        
    else
        print_color "red" "❌ 钱包创建失败"
        exit 1
    fi
}

# 导入钱包
import_wallet() {
    local import_file="$1"
    
    if [ ! -f "$import_file" ]; then
        print_color "red" "❌ 钱包文件不存在: $import_file"
        exit 1
    fi
    
    print_color "blue" "📥 导入钱包文件..."
    
    # 验证钱包文件
    if solana address -k "$import_file" >/dev/null 2>&1; then
        print_color "green" "✅ 钱包文件验证成功"
        
        # 备份现有钱包（如果存在）
        if [ -f "$WALLET_PATH" ]; then
            backup_wallet
        fi
        
        # 复制钱包文件
        local wallet_dir=$(dirname "$WALLET_PATH")
        mkdir -p "$wallet_dir"
        cp "$import_file" "$WALLET_PATH"
        
        # 设置为默认钱包
        solana config set --keypair "$WALLET_PATH"
        
        # 显示钱包信息
        local wallet_address=$(solana address)
        print_color "green" "✅ 钱包导入成功"
        print_color "green" "📍 钱包地址: $wallet_address"
        
    else
        print_color "red" "❌ 钱包文件无效或损坏"
        exit 1
    fi
}

# 设置网络
set_network() {
    local network="$1"
    
    case "$network" in
        localnet)
            local rpc_url="$LOCALNET_RPC"
            ;;
        devnet)
            local rpc_url="$DEVNET_RPC"
            ;;
        testnet)
            local rpc_url="$TESTNET_RPC"
            ;;
        mainnet-beta)
            local rpc_url="$MAINNET_RPC"
            ;;
        *)
            print_color "red" "❌ 无效的网络: $network"
            print_color "blue" "有效选项: localnet, devnet, testnet, mainnet-beta"
            exit 1
            ;;
    esac
    
    print_color "blue" "🌐 设置网络为: $network"
    
    if solana config set --url "$rpc_url"; then
        print_color "green" "✅ 网络设置成功: $network"
        print_color "blue" "RPC端点: $rpc_url"
        
        # 测试网络连接
        print_color "blue" "测试网络连接..."
        if solana cluster-version >/dev/null 2>&1; then
            print_color "green" "✅ 网络连接正常"
        else
            print_color "yellow" "⚠️ 网络连接测试失败，请检查网络设置"
        fi
    else
        print_color "red" "❌ 网络设置失败"
        exit 1
    fi
}

# 获取测试SOL
request_airdrop() {
    local current_network=$(solana config get | grep "RPC URL" | awk '{print $3}')
    
    # 检查是否为测试网络
    if [[ "$current_network" == *"mainnet"* ]]; then
        print_color "red" "❌ 不能在主网上获取空投"
        print_color "blue" "请切换到测试网络 (localnet/devnet/testnet)"
        exit 1
    fi
    
    print_color "blue" "💰 请求测试SOL空投..."
    
    # 检查当前余额
    local current_balance=$(solana balance 2>/dev/null | awk '{print $1}')
    if [ $? -eq 0 ]; then
        print_color "blue" "当前余额: $current_balance SOL"
    fi
    
    # 请求空投
    print_color "blue" "正在请求 2 SOL 空投..."
    if solana airdrop 2; then
        print_color "green" "✅ 空投请求成功"
        
        # 等待确认
        sleep 3
        
        # 检查新余额
        local new_balance=$(solana balance 2>/dev/null | awk '{print $1}')
        if [ $? -eq 0 ]; then
            print_color "green" "💰 新余额: $new_balance SOL"
        fi
    else
        print_color "red" "❌ 空投请求失败"
        print_color "blue" "可能的原因:"
        echo "  1. 网络拥堵，请稍后重试"
        echo "  2. 空投限制，24小时内只能请求一次"
        echo "  3. 网络连接问题"
    fi
}

# 主设置流程
main_setup() {
    local create_new=false
    local import_file=""
    local set_network_name=""
    local request_airdrop_flag=false
    local check_only=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --new|-n)
                create_new=true
                shift
                ;;
            --import)
                import_file="$2"
                shift 2
                ;;
            --network)
                set_network_name="$2"
                shift 2
                ;;
            --airdrop)
                request_airdrop_flag=true
                shift
                ;;
            --check|-c)
                check_only=true
                shift
                ;;
            *)
                print_color "red" "❌ 未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查Solana CLI
    check_solana_cli
    
    print_color "blue" "🚀 开始设置Solana钱包..."
    echo ""
    
    # 如果只是检查状态
    if [ "$check_only" = true ]; then
        check_wallet_status
        exit 0
    fi
    
    # 创建新钱包
    if [ "$create_new" = true ]; then
        create_new_wallet
        echo ""
    fi
    
    # 导入钱包
    if [ -n "$import_file" ]; then
        import_wallet "$import_file"
        echo ""
    fi
    
    # 如果没有钱包，创建新钱包
    if [ ! -f "$WALLET_PATH" ] && [ "$create_new" = false ] && [ -z "$import_file" ]; then
        print_color "yellow" "⚠️ 未找到钱包文件，创建新钱包..."
        create_new_wallet
        echo ""
    fi
    
    # 设置网络
    if [ -n "$set_network_name" ]; then
        set_network "$set_network_name"
        echo ""
    elif [ "$create_new" = true ] || [ -n "$import_file" ]; then
        # 为新钱包设置默认网络
        set_network "$DEFAULT_NETWORK"
        echo ""
    fi
    
    # 请求空投
    if [ "$request_airdrop_flag" = true ]; then
        request_airdrop
        echo ""
    fi
    
    # 显示最终状态
    print_color "green" "🎉 钱包设置完成！"
    echo ""
    check_wallet_status
    
    echo ""
    print_color "blue" "📝 接下来可以："
    echo "  1. 创建项目: ./project/03-create-project.sh"
    echo "  2. 获取更多测试SOL: $0 --airdrop"
    echo "  3. 切换网络: $0 --network devnet"
}

# 执行主流程
main_setup "$@"