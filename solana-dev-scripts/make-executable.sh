#!/bin/bash

# ===================================================================
# 给所有脚本添加执行权限
# 说明：运行此脚本为所有开发脚本添加执行权限
# ===================================================================

echo "🔧 为Solana开发脚本添加执行权限..."

# 查找所有.sh文件并添加执行权限
find . -name "*.sh" -type f -exec chmod +x {} \;

echo "✅ 执行权限已添加到以下文件："
find . -name "*.sh" -type f -exec ls -la {} \;

echo ""
echo "🎉 所有脚本现在都可以执行了！"
echo ""
echo "📝 接下来可以："
echo "  1. 查看快速开始指南: cat 快速开始指南.md"
echo "  2. 配置项目信息: nano config/project-config.sh"
echo "  3. 安装开发工具: ./setup/01-install-tools.sh"