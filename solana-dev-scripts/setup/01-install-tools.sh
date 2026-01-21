#!/bin/bash

# ===================================================================
# Solana开发工具安装脚本
# 说明：自动安装Solana开发所需的工具链
# ===================================================================

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_FILE="$SCRIPT_DIR/../config/project-config.sh"

# 加载配置文件
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "❌ 未找到配置文件: $CONFIG_FILE"
    echo "请确保配置文件存在并已正确设置"
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
    echo "Solana开发工具安装脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h      显示此帮助信息"
    echo "  --check, -c     仅检查工具安装状态，不进行安装"
    echo "  --force, -f     强制重新安装所有工具"
    echo "  --skip-rust     跳过Rust安装"
    echo "  --skip-node     跳过Node.js检查"
    echo ""
    echo "说明:"
    echo "  此脚本会自动安装以下工具："
    echo "  - Rust编程语言"
    echo "  - Solana CLI工具链"
    echo "  - Anchor框架"
    echo "  并检查Node.js是否已安装"
}

# 检查命令是否存在
check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 检查工具安装状态
check_tools() {
    print_color "blue" "🔍 检查开发工具安装状态..."
    echo ""
    
    local all_ok=true
    
    # 检查Rust
    if check_command "rustc"; then
        local rust_version=$(rustc --version | cut -d' ' -f2)
        print_color "green" "✅ Rust: $rust_version"
    else
        print_color "red" "❌ Rust: 未安装"
        all_ok=false
    fi
    
    # 检查Cargo
    if check_command "cargo"; then
        local cargo_version=$(cargo --version | cut -d' ' -f2)
        print_color "green" "✅ Cargo: $cargo_version"
    else
        print_color "red" "❌ Cargo: 未安装"
        all_ok=false
    fi
    
    # 检查Solana CLI
    if check_command "solana"; then
        local solana_version=$(solana --version | cut -d' ' -f2)
        print_color "green" "✅ Solana CLI: $solana_version"
    else
        print_color "red" "❌ Solana CLI: 未安装"
        all_ok=false
    fi
    
    # 检查Anchor
    if check_command "anchor"; then
        local anchor_version=$(anchor --version | cut -d' ' -f2)
        print_color "green" "✅ Anchor: $anchor_version"
    else
        print_color "red" "❌ Anchor: 未安装"
        all_ok=false
    fi
    
    # 检查Node.js
    if check_command "node"; then
        local node_version=$(node --version)
        local major_version=$(echo $node_version | sed 's/v\([0-9]*\)\..*/\1/')
        if [ "$major_version" -ge "$NODE_VERSION" ]; then
            print_color "green" "✅ Node.js: $node_version"
        else
            print_color "yellow" "⚠️  Node.js: $node_version (建议升级到 v$NODE_VERSION+)"
        fi
    else
        print_color "red" "❌ Node.js: 未安装"
        all_ok=false
    fi
    
    # 检查Yarn或npm
    if check_command "yarn"; then
        local yarn_version=$(yarn --version)
        print_color "green" "✅ Yarn: $yarn_version"
    elif check_command "npm"; then
        local npm_version=$(npm --version)
        print_color "green" "✅ npm: $npm_version"
    else
        print_color "red" "❌ 包管理器: 未安装yarn或npm"
        all_ok=false
    fi
    
    echo ""
    if [ "$all_ok" = true ]; then
        print_color "green" "🎉 所有开发工具已正确安装！"
        return 0
    else
        print_color "red" "❌ 部分开发工具缺失，需要安装"
        return 1
    fi
}

# 安装Rust
install_rust() {
    if [ "$SKIP_RUST" = true ]; then
        print_color "yellow" "⏭️ 跳过Rust安装"
        return 0
    fi
    
    if check_command "rustc" && [ "$FORCE_INSTALL" != true ]; then
        print_color "green" "✅ Rust已安装，跳过安装步骤"
        return 0
    fi
    
    print_color "blue" "📦 安装Rust编程语言..."
    
    # 下载并安装Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # 重新加载环境变量
    source ~/.cargo/env
    
    # 验证安装
    if check_command "rustc"; then
        print_color "green" "✅ Rust安装成功"
        
        # 安装必要的组件
        rustup component add rustfmt clippy
        print_color "green" "✅ Rust组件安装完成"
    else
        print_color "red" "❌ Rust安装失败"
        return 1
    fi
}

# 安装Solana CLI
install_solana() {
    if check_command "solana" && [ "$FORCE_INSTALL" != true ]; then
        print_color "green" "✅ Solana CLI已安装，跳过安装步骤"
        
        # 检查 BPF SDK
        if ! check_command "cargo-build-sbf"; then
            print_color "yellow" "⚠️ BPF SDK 未安装，正在安装..."
            install_bpf_sdk
        else
            # 即使 cargo-build-sbf 存在，也要确保 SDK 已下载
            print_color "blue" "🔍 验证 BPF SDK..."
            if ! find ~/.cache/solana -name "sbf" -type d 2>/dev/null | grep -q .; then
                print_color "yellow" "⚠️ SDK 未下载，正在下载..."
                install_bpf_sdk
            else
                print_color "green" "✅ BPF SDK 已就绪"
            fi
        fi
        return 0
    fi
    
    print_color "blue" "📦 安装Solana CLI工具链..."
    
    # 使用 Agave 官方安装（包含 cargo-build-sbf）
    print_color "yellow" "正在安装 Agave 工具链（包含 Solana CLI 和 cargo-build-sbf）..."
    
    # 尝试 Agave 官方源
    if sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)" 2>/dev/null; then
        print_color "green" "✅ Agave 安装成功"
    else
        print_color "yellow" "⚠️ Agave 源失败，尝试 Solana 官方源..."
        sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
    fi
    
    # 添加到PATH（如果还没有的话）
    if ! echo $PATH | grep -q "$HOME/.local/share/solana/install/active_release/bin"; then
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    fi
    
    # 验证安装
    if check_command "solana"; then
        INSTALLED_VERSION=$(solana --version | cut -d' ' -f2)
        print_color "green" "✅ Solana CLI 安装成功: v$INSTALLED_VERSION"
        print_color "blue" "🔧 配置Solana CLI..."
        
        # 配置默认网络
        solana config set --url "$DEFAULT_NETWORK"
        print_color "green" "✅ 默认网络设置为: $DEFAULT_NETWORK"
        
        # 安装 BPF SDK
        install_bpf_sdk
    else
        print_color "red" "❌ Solana CLI安装失败"
        return 1
    fi
}

# 安装 BPF SDK (Platform Tools)
install_bpf_sdk() {
    print_color "blue" "📦 安装Solana BPF编译工具链 (cargo-build-sbf)..."
    echo ""
    
    # 步骤1: 卸载旧版本（如果存在）
    if [ "$FORCE_INSTALL" = true ]; then
        print_color "yellow" "🧹 卸载旧版本 cargo-build-sbf..."
        cargo uninstall cargo-build-sbf 2>/dev/null || true
        print_color "green" "✅ 清理完成"
        echo ""
    fi
    
    # 步骤2: 从 Agave 安装最新版本
    print_color "blue" "步骤 1/3: 从 Agave 安装 cargo-build-sbf..."
    print_color "yellow" "这将安装最新兼容版本，可能需要几分钟..."
    echo ""
    
    # 显示安装进度（不过滤警告，让用户看到进度）
    if cargo install --git https://github.com/anza-xyz/agave cargo-build-sbf --locked --force; then
        print_color "green" "✅ cargo-build-sbf 安装成功"
    else
        print_color "red" "❌ cargo-build-sbf 安装失败"
        print_color "yellow" "请检查网络连接和 Rust 环境"
        return 1
    fi
    
    echo ""
    
    # 步骤3: 清理旧的 SDK 缓存
    print_color "blue" "步骤 2/3: 准备 SDK 环境..."
    
    if [ "$FORCE_INSTALL" = true ] && [ -d ~/.cache/solana ]; then
        print_color "yellow" "清理旧的 SDK 缓存..."
        rm -rf ~/.cache/solana/*
        print_color "green" "✅ 缓存已清理"
    fi
    
    # 确保缓存目录存在
    mkdir -p ~/.cache/solana
    echo ""
    
    # 步骤4: 下载 BPF SDK
    print_color "blue" "步骤 3/3: 下载 BPF SDK (约50-100MB)..."
    print_color "yellow" "⏳ 这是一次性下载，首次可能需要 5-10 分钟"
    print_color "yellow" "⏳ 请不要中断，让下载完成..."
    echo ""
    
    # 强制下载 SDK，显示所有输出
    if cargo build-sbf --force-tools-install 2>&1 | tee /tmp/bpf-sdk-install.log; then
        print_color "green" "✅ BPF SDK 下载成功"
    else
        # 检查是否实际下载成功
        print_color "yellow" "⚠️ 下载过程显示警告，正在验证..."
        sleep 2
        
        # 验证 cargo-build-sbf 是否可用
        if cargo build-sbf --version &> /dev/null 2>&1; then
            print_color "green" "✅ 验证成功，SDK 已就绪"
        else
            print_color "yellow" "⚠️ SDK 可能未完全下载"
            print_color "blue" "💡 这通常不影响使用，首次构建时会自动补全"
        fi
    fi
    
    echo ""
    
    # 步骤5: 验证安装
    print_color "blue" "🔍 最终验证..."
    
    # 检查 cargo-build-sbf 版本
    if command -v cargo-build-sbf &> /dev/null; then
        VERSION=$(cargo-build-sbf --version 2>&1 | head -1)
        print_color "green" "✅ cargo-build-sbf: $VERSION"
    else
        print_color "red" "❌ cargo-build-sbf 不可用"
        return 1
    fi
    
    # 检查 SDK 目录
    if [ -d ~/.cache/solana ]; then
        SDK_DIRS=$(find ~/.cache/solana -name "sbf" -type d 2>/dev/null)
        if [ -n "$SDK_DIRS" ]; then
            print_color "green" "✅ BPF SDK 已安装:"
            echo "$SDK_DIRS" | head -3 | while read -r dir; do
                SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
                echo "   📁 $dir ($SIZE)"
            done
        else
            print_color "yellow" "⚠️ SDK 目录未找到"
            print_color "blue" "💡 首次构建时会自动下载"
        fi
    fi
    
    echo ""
    print_color "green" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "green" "🎉 BPF 编译工具链配置完成！"
    print_color "green" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 安装Anchor
install_anchor() {
    if check_command "anchor" && [ "$FORCE_INSTALL" != true ]; then
        print_color "green" "✅ Anchor已安装，跳过安装步骤"
        return 0
    fi
    
    print_color "blue" "📦 安装Anchor框架..."
    
    # 安装avm (Anchor Version Manager)
    cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
    
    # 安装指定版本的Anchor
    avm install $ANCHOR_VERSION
    avm use $ANCHOR_VERSION
    
    # 验证安装
    if check_command "anchor"; then
        print_color "green" "✅ Anchor安装成功"
    else
        print_color "red" "❌ Anchor安装失败"
        return 1
    fi
}

# 检查Node.js
check_nodejs() {
    if [ "$SKIP_NODE" = true ]; then
        print_color "yellow" "⏭️ 跳过Node.js检查"
        return 0
    fi
    
    print_color "blue" "🔍 检查Node.js..."
    
    if check_command "node"; then
        local node_version=$(node --version)
        local major_version=$(echo $node_version | sed 's/v\([0-9]*\)\..*/\1/')
        
        if [ "$major_version" -ge "$NODE_VERSION" ]; then
            print_color "green" "✅ Node.js版本符合要求: $node_version"
        else
            print_color "yellow" "⚠️ Node.js版本过低: $node_version"
            print_color "yellow" "建议升级到 v$NODE_VERSION 或更高版本"
            print_color "blue" "可以访问 https://nodejs.org 下载最新版本"
        fi
    else
        print_color "red" "❌ Node.js未安装"
        print_color "blue" "请访问 https://nodejs.org 下载并安装Node.js"
        return 1
    fi
}

# 创建开发目录
setup_directories() {
    print_color "blue" "📁 创建开发目录..."
    
    # 确保日志目录存在
    mkdir -p "$LOG_DIR"
    
    print_color "green" "✅ 目录设置完成"
}

# 主安装流程
main_install() {
    print_color "blue" "🚀 开始安装Solana开发工具..."
    echo ""
    
    # 创建开发目录
    setup_directories
    
    # 安装Rust
    install_rust
    if [ $? -ne 0 ]; then
        print_color "red" "❌ Rust安装失败，停止安装"
        exit 1
    fi
    
    # 安装Solana CLI
    install_solana
    if [ $? -ne 0 ]; then
        print_color "red" "❌ Solana CLI安装失败，停止安装"
        exit 1
    fi
    
    # 安装Anchor
    install_anchor
    if [ $? -ne 0 ]; then
        print_color "red" "❌ Anchor安装失败，停止安装"
        exit 1
    fi
    
    # 检查Node.js
    check_nodejs
    
    echo ""
    print_color "green" "🎉 开发工具安装完成！"
    echo ""
    print_color "blue" "📝 接下来的步骤："
    echo "  1. 重新启动终端或运行: source ~/.bashrc"
    echo "  2. 运行: ./setup/02-setup-wallet.sh 设置钱包"
    echo "  3. 运行: ./project/03-create-project.sh 创建项目"
}

# 参数解析
FORCE_INSTALL=false
CHECK_ONLY=false
SKIP_RUST=false
SKIP_NODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --check|-c)
            CHECK_ONLY=true
            shift
            ;;
        --force|-f)
            FORCE_INSTALL=true
            shift
            ;;
        --skip-rust)
            SKIP_RUST=true
            shift
            ;;
        --skip-node)
            SKIP_NODE=true
            shift
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 --help 查看可用选项"
            exit 1
            ;;
    esac
done

# 执行主流程
if [ "$CHECK_ONLY" = true ]; then
    check_tools
else
    main_install
fi