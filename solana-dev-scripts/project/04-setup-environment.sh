#!/bin/bash

# ===================================================================
# Solana项目环境设置脚本
# 说明：设置项目环境变量和依赖配置
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
    echo "Solana项目环境设置脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h          显示此帮助信息"
    echo "  --check, -c         仅检查环境状态"
    echo "  --reset             重置环境配置"
    echo "  --install-deps      安装项目依赖"
    echo ""
    echo "说明:"
    echo "  此脚本会设置项目的环境变量和依赖配置"
    echo "  包括安装Node.js依赖、配置IDE等"
}

# 检查是否在项目根目录
check_project_root() {
    if [ ! -f "Anchor.toml" ] && [ ! -f "Cargo.toml" ]; then
        print_color "red" "❌ 请在项目根目录下运行此脚本"
        print_color "blue" "提示：项目根目录应包含 Anchor.toml 或 Cargo.toml 文件"
        exit 1
    fi
}

# 检查环境状态
check_environment() {
    print_color "blue" "🔍 检查项目环境..."
    echo ""
    
    local all_ok=true
    
    # 检查Node.js依赖
    if [ -f "package.json" ]; then
        if [ -d "node_modules" ]; then
            print_color "green" "✅ Node.js依赖已安装"
        else
            print_color "yellow" "⚠️ Node.js依赖未安装"
            all_ok=false
        fi
    else
        print_color "yellow" "⚠️ 未找到package.json"
    fi
    
    # 检查Rust依赖
    if [ -f "Cargo.toml" ]; then
        print_color "green" "✅ 找到Cargo.toml"
    else
        print_color "yellow" "⚠️ 未找到Cargo.toml"
    fi
    
    # 检查Anchor配置
    if [ -f "Anchor.toml" ]; then
        print_color "green" "✅ 找到Anchor.toml"
        
        # 检查程序密钥对
        if [ -d "target/deploy" ] && ls target/deploy/*-keypair.json >/dev/null 2>&1; then
            print_color "green" "✅ 程序密钥对已存在"
        else
            print_color "yellow" "⚠️ 程序密钥对未生成"
            all_ok=false
        fi
    else
        print_color "yellow" "⚠️ 未找到Anchor.toml"
    fi
    
    # 检查环境变量文件
    if [ -f ".env" ]; then
        print_color "green" "✅ 环境变量文件已配置"
    else
        print_color "yellow" "⚠️ 环境变量文件不存在"
    fi
    
    # 检查IDE配置
    if [ -d ".vscode" ]; then
        print_color "green" "✅ VSCode配置已存在"
    else
        print_color "yellow" "⚠️ VSCode配置未设置"
    fi
    
    echo ""
    if [ "$all_ok" = true ]; then
        print_color "green" "🎉 项目环境配置完整！"
        return 0
    else
        print_color "yellow" "⚠️ 部分环境配置缺失，建议运行完整设置"
        return 1
    fi
}

# 安装项目依赖
install_dependencies() {
    print_color "blue" "📦 安装项目依赖..."
    
    # 检查package.json
    if [ ! -f "package.json" ]; then
        print_color "yellow" "⚠️ 未找到package.json，跳过依赖安装"
        return 0
    fi
    
    # 选择包管理器
    local package_manager=""
    if command -v yarn &> /dev/null; then
        package_manager="yarn"
    elif command -v npm &> /dev/null; then
        package_manager="npm"
    else
        print_color "red" "❌ 未找到包管理器 (yarn或npm)"
        return 1
    fi
    
    print_color "blue" "使用包管理器: $package_manager"
    
    # 安装依赖
    if [ "$package_manager" = "yarn" ]; then
        if yarn install; then
            print_color "green" "✅ 依赖安装成功"
        else
            print_color "red" "❌ 依赖安装失败"
            return 1
        fi
    else
        if npm install; then
            print_color "green" "✅ 依赖安装成功"
        else
            print_color "red" "❌ 依赖安装失败"
            return 1
        fi
    fi
}

# 设置环境变量
setup_env_file() {
    print_color "blue" "📝 设置环境变量文件..."
    
    # 如果.env已存在，备份
    if [ -f ".env" ]; then
        cp .env .env.backup
        print_color "blue" "已备份现有.env文件"
    fi
    
    # 创建.env文件
    cat > .env << EOF
# Solana网络配置
ANCHOR_PROVIDER_URL=${DEVNET_RPC}
ANCHOR_WALLET=${WALLET_PATH}

# 项目信息
PROJECT_NAME=${PROJECT_NAME}
DEVELOPER_NAME=${DEVELOPER_NAME}
DEVELOPER_EMAIL=${DEVELOPER_EMAIL}

# 网络配置
DEFAULT_NETWORK=${DEFAULT_NETWORK}
LOCALNET_RPC=${LOCALNET_RPC}
DEVNET_RPC=${DEVNET_RPC}
TESTNET_RPC=${TESTNET_RPC}
MAINNET_RPC=${MAINNET_RPC}

# 日志配置
LOG_LEVEL=info
EOF

    print_color "green" "✅ 环境变量文件创建成功"
    
    # 创建.env.example
    cat > .env.example << 'EOF'
# Solana网络配置
ANCHOR_PROVIDER_URL=https://api.devnet.solana.com
ANCHOR_WALLET=~/.config/solana/id.json

# 项目信息
PROJECT_NAME=my_solana_project
DEVELOPER_NAME=Your Name
DEVELOPER_EMAIL=your@email.com

# 网络配置
DEFAULT_NETWORK=devnet
LOCALNET_RPC=http://127.0.0.1:8899
DEVNET_RPC=https://api.devnet.solana.com
TESTNET_RPC=https://api.testnet.solana.com
MAINNET_RPC=https://api.mainnet-beta.solana.com

# 日志配置
LOG_LEVEL=info
EOF

    print_color "green" "✅ 环境变量示例文件创建成功"
}

# 设置VSCode配置
setup_vscode_config() {
    print_color "blue" "⚙️ 设置VSCode配置..."
    
    mkdir -p .vscode
    
    # settings.json
    cat > .vscode/settings.json << 'EOF'
{
    "rust-analyzer.cargo.target": "bpfel-unknown-unknown",
    "rust-analyzer.check.allTargets": false,
    "files.watcherExclude": {
        "**/target/**": true,
        "**/node_modules/**": true,
        "**/test-ledger/**": true
    },
    "search.exclude": {
        "**/target": true,
        "**/node_modules": true,
        "**/test-ledger": true
    },
    "files.exclude": {
        "**/.anchor": true
    },
    "editor.formatOnSave": true,
    "[rust]": {
        "editor.defaultFormatter": "rust-lang.rust-analyzer",
        "editor.formatOnSave": true
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    },
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    }
}
EOF

    # extensions.json
    cat > .vscode/extensions.json << 'EOF'
{
    "recommendations": [
        "rust-lang.rust-analyzer",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "ms-vscode.vscode-typescript-next"
    ]
}
EOF

    # launch.json
    cat > .vscode/launch.json << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "node",
            "request": "launch",
            "name": "Anchor Test",
            "runtimeExecutable": "anchor",
            "runtimeArgs": ["test"],
            "console": "integratedTerminal"
        }
    ]
}
EOF

    print_color "green" "✅ VSCode配置创建成功"
}

# 生成程序密钥对
generate_program_keypairs() {
    print_color "blue" "🔑 检查程序密钥对..."
    
    # 确保目录存在
    mkdir -p target/deploy
    
    # 查找程序名称
    if [ -f "Anchor.toml" ]; then
        # 从Anchor.toml获取程序名称
        local programs=$(grep -A 10 "\[programs.localnet\]" Anchor.toml | grep -v "^#" | grep "=" | cut -d'=' -f1 | tr -d ' ')
        
        for program in $programs; do
            local keypair_file="target/deploy/${program}-keypair.json"
            
            if [ -f "$keypair_file" ]; then
                local program_id=$(solana address -k "$keypair_file" 2>/dev/null)
                print_color "green" "✅ 程序密钥对已存在: $program ($program_id)"
            else
                print_color "blue" "生成新的程序密钥对: $program"
                if solana-keygen new -o "$keypair_file" --no-bip39-passphrase; then
                    local program_id=$(solana address -k "$keypair_file")
                    print_color "green" "✅ 程序密钥对生成成功: $program ($program_id)"
                else
                    print_color "red" "❌ 程序密钥对生成失败: $program"
                fi
            fi
        done
    else
        print_color "yellow" "⚠️ 未找到Anchor.toml，跳过程序密钥对生成"
    fi
}

# 创建项目脚本
create_project_scripts() {
    print_color "blue" "📜 创建项目脚本..."
    
    mkdir -p scripts
    
    # 如果脚本目录下已有脚本，跳过
    if [ -f "scripts/build.sh" ]; then
        print_color "yellow" "⚠️ 项目脚本已存在，跳过创建"
        return 0
    fi
    
    # 创建构建脚本
    cat > scripts/build.sh << 'EOF'
#!/bin/bash
echo "🔨 构建项目..."
anchor build

echo "📏 检查程序大小..."
if [ -d "./target/deploy" ]; then
    du -sh ./target/deploy/*.so 2>/dev/null || echo "无程序文件"
fi
EOF

    # 创建测试脚本
    cat > scripts/test.sh << 'EOF'
#!/bin/bash
echo "🧪 运行测试..."
anchor test
EOF

    # 创建部署脚本
    cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
NETWORK=${1:-devnet}
echo "🚀 部署到 $NETWORK..."

# 检查余额
echo "检查钱包余额..."
solana balance

# 部署程序
anchor deploy --provider.cluster $NETWORK

echo "✅ 部署完成！"
EOF

    # 设置脚本权限
    chmod +x scripts/*.sh
    
    print_color "green" "✅ 项目脚本创建成功"
}

# 重置环境
reset_environment() {
    print_color "yellow" "⚠️ 重置项目环境..."
    
    # 备份现有配置
    local backup_dir="$BACKUP_DIR/env-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [ -f ".env" ]; then
        cp .env "$backup_dir/"
        print_color "blue" "已备份.env文件"
    fi
    
    if [ -d ".vscode" ]; then
        cp -r .vscode "$backup_dir/"
        print_color "blue" "已备份.vscode目录"
    fi
    
    # 删除现有配置
    rm -f .env
    rm -rf .vscode
    
    print_color "green" "✅ 环境已重置，备份保存在: $backup_dir"
}

# 主设置流程
main_setup() {
    local check_only=false
    local reset=false
    local install_deps=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --check|-c)
                check_only=true
                shift
                ;;
            --reset)
                reset=true
                shift
                ;;
            --install-deps)
                install_deps=true
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
    
    print_color "blue" "🚀 开始设置项目环境..."
    echo ""
    
    # 如果只是检查状态
    if [ "$check_only" = true ]; then
        check_environment
        exit 0
    fi
    
    # 重置环境
    if [ "$reset" = true ]; then
        reset_environment
        echo ""
    fi
    
    # 安装依赖
    if [ "$install_deps" = true ]; then
        install_dependencies
        echo ""
    fi
    
    # 设置环境变量
    setup_env_file
    echo ""
    
    # 设置VSCode配置
    setup_vscode_config
    echo ""
    
    # 生成程序密钥对
    generate_program_keypairs
    echo ""
    
    # 创建项目脚本
    create_project_scripts
    echo ""
    
    # 显示最终状态
    print_color "green" "🎉 项目环境设置完成！"
    echo ""
    check_environment
    
    echo ""
    print_color "blue" "📝 接下来可以："
    echo "  1. 构建项目: ./scripts/build.sh 或 ../development/05-build.sh"
    echo "  2. 运行测试: ./scripts/test.sh 或 ../development/06-test.sh"
    echo "  3. 部署项目: ./scripts/deploy.sh devnet"
}

# 执行主流程
main_setup "$@"
