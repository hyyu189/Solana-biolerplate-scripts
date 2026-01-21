#!/bin/bash

echo "🔍 Solana 环境诊断工具"
echo "===================="
echo ""

echo "1️⃣ 检查 cargo-build-sbf 命令..."
if command -v cargo-build-sbf &> /dev/null; then
    echo "✅ cargo-build-sbf 存在"
    cargo-build-sbf --version 2>&1 | head -5
else
    echo "❌ cargo-build-sbf 不存在"
fi
echo ""

echo "2️⃣ 检查 cargo-build-sbf 位置..."
which cargo-build-sbf 2>/dev/null || echo "❌ 未找到"
echo ""

echo "3️⃣ 检查 Solana 缓存目录..."
if [ -d ~/.cache/solana ]; then
    echo "✅ 缓存目录存在: ~/.cache/solana"
    echo "📁 目录内容:"
    ls -la ~/.cache/solana/ 2>/dev/null | head -10
else
    echo "❌ 缓存目录不存在"
fi
echo ""

echo "4️⃣ 查找 BPF SDK..."
echo "🔍 搜索 sbf 目录..."
find ~/.cache/solana -name "sbf" -type d 2>/dev/null | head -5
echo ""

echo "5️⃣ 检查错误路径..."
echo "🔍 检查 /Users/haiyangyu/.cargo/bin/sdk/sbf"
if [ -d "/Users/haiyangyu/.cargo/bin/sdk/sbf" ]; then
    echo "✅ 存在"
else
    echo "❌ 不存在 (这是错误的路径)"
fi
echo ""

echo "6️⃣ 检查 Cargo 配置..."
if [ -f ~/.cargo/config ]; then
    echo "✅ ~/.cargo/config 存在"
    cat ~/.cargo/config
else
    echo "ℹ️ ~/.cargo/config 不存在"
fi
echo ""

echo "7️⃣ 检查 Solana 版本..."
solana --version 2>&1 || echo "❌ Solana CLI 有问题"
echo ""

echo "8️⃣ 检查 Anchor 版本..."
anchor --version 2>&1 || echo "❌ Anchor 有问题"
echo ""

echo "9️⃣ 尝试运行 cargo build-sbf..."
echo "测试命令: cargo build-sbf --version"
cargo build-sbf --version 2>&1 || echo "❌ 执行失败"
echo ""

echo "🔟 环境变量检查..."
echo "PATH:"
echo $PATH | tr ':' '\n' | grep -E '(cargo|solana)' || echo "未找到相关路径"
echo ""

echo "📝 诊断完成！"
