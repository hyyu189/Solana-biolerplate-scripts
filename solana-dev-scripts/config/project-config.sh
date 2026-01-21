#!/bin/bash

# ===================================================================
# Solana项目配置文件
# 说明：初学者只需要修改这个文件中的配置项即可
# ===================================================================

# 📝 项目基本信息
# 项目名称（英文，不要有空格和特殊字符）
PROJECT_NAME="my_solana_project"

# 项目描述
PROJECT_DESCRIPTION="我的第一个Solana项目"

# 开发者姓名
DEVELOPER_NAME="你的姓名"

# 开发者邮箱
DEVELOPER_EMAIL="your.email@example.com"

# ===================================================================
# 🔧 开发环境配置
# ===================================================================

# Solana工具链版本
SOLANA_VERSION="1.18.0"

# Anchor框架版本  
ANCHOR_VERSION="0.29.0"

# Node.js版本要求
NODE_VERSION="18"

# ===================================================================
# 🌐 网络配置
# ===================================================================

# 默认使用的网络环境
# 选项: "localnet" | "devnet" | "testnet" | "mainnet-beta"
DEFAULT_NETWORK="devnet"

# 各网络的RPC端点
LOCALNET_RPC="http://127.0.0.1:8899"
DEVNET_RPC="https://api.devnet.solana.com"
TESTNET_RPC="https://api.testnet.solana.com"
MAINNET_RPC="https://api.mainnet-beta.solana.com"

# ===================================================================
# 💰 钱包配置
# ===================================================================

# 钱包文件路径（建议使用默认值）
WALLET_PATH="$HOME/.config/solana/id.json"

# 程序密钥对文件路径（会自动生成）
PROGRAM_KEYPAIR_PATH="./target/deploy/${PROJECT_NAME}-keypair.json"

# ===================================================================
# 🚀 部署配置
# ===================================================================

# 是否在部署前自动构建程序
AUTO_BUILD_BEFORE_DEPLOY=true

# 是否在部署前检查余额
CHECK_BALANCE_BEFORE_DEPLOY=true

# 最小SOL余额要求（用于支付部署费用）
MIN_BALANCE_SOL=1.0

# ===================================================================
# 🧪 测试配置
# ===================================================================

# 是否运行测试时显示详细输出
VERBOSE_TESTS=true

# 测试网络设置
TEST_NETWORK="localnet"

# 是否在测试前自动启动本地验证器
AUTO_START_VALIDATOR=true

# ===================================================================
# 📊 监控配置
# ===================================================================

# 监控程序日志的默认时长（秒）
MONITOR_DURATION=60

# 是否启用彩色输出
ENABLE_COLORS=true

# ===================================================================
# 🛠️ 高级配置（初学者通常不需要修改）
# ===================================================================

# 构建优化级别
BUILD_OPTIMIZATION="release"

# 并行构建线程数
BUILD_JOBS=4

# 程序大小限制检查（字节）
MAX_PROGRAM_SIZE=1048576  # 1MB

# 日志文件路径
LOG_DIR="./logs"

# 备份目录
BACKUP_DIR="./backups"

# ===================================================================
# 📋 配置验证函数
# ===================================================================

validate_config() {
    local errors=0
    
    # 检查项目名称
    if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo "❌ 错误：项目名称只能包含字母、数字和下划线，且必须以字母开头"
        errors=$((errors + 1))
    fi
    
    # 检查邮箱格式
    if [[ ! "$DEVELOPER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "❌ 错误：请输入有效的邮箱地址"
        errors=$((errors + 1))
    fi
    
    # 检查网络配置
    if [[ ! "$DEFAULT_NETWORK" =~ ^(localnet|devnet|testnet|mainnet-beta)$ ]]; then
        echo "❌ 错误：默认网络必须是 localnet、devnet、testnet 或 mainnet-beta 之一"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        echo "✅ 配置验证通过"
        return 0
    else
        echo "❌ 发现 $errors 个配置错误，请修正后重试"
        return 1
    fi
}

# ===================================================================
# 📖 配置说明函数
# ===================================================================

show_config_help() {
    echo "📋 配置文件说明："
    echo ""
    echo "🔧 必需修改的配置项："
    echo "  PROJECT_NAME      - 你的项目名称（英文）"
    echo "  DEVELOPER_NAME    - 你的姓名"
    echo "  DEVELOPER_EMAIL   - 你的邮箱"
    echo ""
    echo "🌐 网络配置："
    echo "  DEFAULT_NETWORK   - 默认使用的网络"
    echo "    - localnet: 本地测试网络"
    echo "    - devnet: 开发测试网络（推荐初学者使用）"
    echo "    - testnet: 公共测试网络"
    echo "    - mainnet-beta: 主网（生产环境）"
    echo ""
    echo "💰 钱包配置："
    echo "  WALLET_PATH       - 钱包文件存储路径（建议使用默认值）"
    echo ""
    echo "🚀 部署配置："
    echo "  AUTO_BUILD_BEFORE_DEPLOY - 部署前是否自动构建"
    echo "  MIN_BALANCE_SOL          - 最小SOL余额要求"
    echo ""
    echo "🧪 测试配置："
    echo "  VERBOSE_TESTS     - 是否显示详细测试输出"
    echo "  TEST_NETWORK      - 测试使用的网络"
    echo ""
    echo "其他配置项通常不需要修改，除非你有特殊需求。"
}

# 如果直接运行此文件，显示配置说明
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        --help|-h)
            show_config_help
            ;;
        --validate|-v)
            validate_config
            ;;
        *)
            echo "当前配置："
            echo "项目名称: $PROJECT_NAME"
            echo "开发者: $DEVELOPER_NAME"
            echo "邮箱: $DEVELOPER_EMAIL"
            echo "默认网络: $DEFAULT_NETWORK"
            echo ""
            echo "使用方法："
            echo "  bash $0 --help     查看配置说明"
            echo "  bash $0 --validate 验证配置"
            ;;
    esac
fi