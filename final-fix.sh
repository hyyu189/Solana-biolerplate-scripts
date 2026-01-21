#!/bin/bash

set -e

echo "🔧 Solana 环境终极修复"
echo "======================="
echo ""

# 步骤 1: 清理环境
echo "🧹 步骤 1/4: 清理旧环境..."
rm -rf ~/.cache/solana/* 2>/dev/null || true
cargo uninstall cargo-build-sbf 2>/dev/null || true
echo "✅ 清理完成"
echo ""

# 步骤 2: 安装最新 Agave 工具链
echo "📦 步骤 2/4: 安装 Agave 工具链 (v2.1.0)..."
echo "这包含了 Solana CLI 和 cargo-build-sbf"
echo ""

# 使用 Agave 官方安装脚本
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"

echo ""
echo "✅ Agave 工具链安装完成"
echo ""

# 步骤 3: 配置环境变量
echo "⚙️ 步骤 3/4: 配置环境变量..."

# 检测安装路径
SOLANA_INSTALL_PATH="$HOME/.local/share/solana/install/active_release/bin"

# 添加到 PATH
if ! grep -q "$SOLANA_INSTALL_PATH" ~/.bashrc 2>/dev/null; then
    echo "export PATH=\"$SOLANA_INSTALL_PATH:\$PATH\"" >> ~/.bashrc
fi

if [ -f ~/.zshrc ]; then
    if ! grep -q "$SOLANA_INSTALL_PATH" ~/.zshrc 2>/dev/null; then
        echo "export PATH=\"$SOLANA_INSTALL_PATH:\$PATH\"" >> ~/.zshrc
    fi
fi

# 临时添加到当前环境
export PATH="$SOLANA_INSTALL_PATH:$PATH"

echo "✅ 环境变量已配置"
echo ""

# 步骤 4: 下载 BPF SDK
echo "📥 步骤 4/4: 下载 BPF SDK..."
echo "这可能需要几分钟，请耐心等待..."
echo ""

# 重新加载环境以确保 cargo-build-sbf 可用
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# 直接使用 cargo-build-sbf 下载 SDK
if command -v cargo-build-sbf &> /dev/null; then
    echo "使用 cargo-build-sbf 下载 SDK..."
    cargo build-sbf --force-tools-install 2>&1 | tee /tmp/bpf-sdk-download.log
    
    if [ $? -eq 0 ] || find ~/.cache/solana -name "sbf" -type d 2>/dev/null | grep -q .; then
        echo ""
        echo "✅ BPF SDK 下载完成"
    else
        echo ""
        echo "⚠️ SDK 下载可能未完全成功，但首次构建时会自动补全"
    fi
else
    echo "❌ cargo-build-sbf 未找到"
    echo "💡 请尝试重启终端后再次运行此脚本"
fi

echo ""

# 验证安装
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 验证安装"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "1. Solana 版本:"
if command -v solana &> /dev/null; then
    solana --version
else
    echo "❌ Solana 未找到"
fi

echo ""
echo "2. cargo-build-sbf 版本:"
if command -v cargo-build-sbf &> /dev/null; then
    cargo-build-sbf --version 2>&1 | head -1
else
    echo "❌ cargo-build-sbf 未找到"
fi

echo ""
echo "3. BPF SDK 路径:"
if [ -d ~/.cache/solana ]; then
    find ~/.cache/solana -name "sbf" -type d 2>/dev/null | head -3 || echo "未找到 SDK 目录"
else
    echo "缓存目录不存在"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 修复完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 下一步操作："
echo ""
echo "1. 重新加载环境:"
echo "   source ~/.bashrc"
echo "   # 或者"
echo "   source ~/.zshrc"
echo ""
echo "2. 或者重启终端"
echo ""
echo "3. 测试构建:"
echo "   cd my_solana_project"
echo "   anchor build"
echo ""
