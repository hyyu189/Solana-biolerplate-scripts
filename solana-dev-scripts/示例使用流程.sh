#!/bin/bash

# ===================================================================
# Solana开发脚本使用示例
# 说明：这个脚本演示了完整的Solana项目开发流程
# 注意：这是示例脚本，实际使用时请分步执行
# ===================================================================

echo "🚀 Solana开发脚本使用示例"
echo "========================================"
echo ""

# 颜色输出函数
print_step() {
    echo -e "\033[34m📋 步骤 $1: $2\033[0m"
}

print_command() {
    echo -e "\033[32m💻 命令: $1\033[0m"
}

print_note() {
    echo -e "\033[33m💡 说明: $1\033[0m"
}

echo "本示例演示完整的Solana项目开发流程："
echo ""

# 步骤 1
print_step "1" "配置项目信息"
print_command "nano config/project-config.sh"
print_note "修改项目名称、开发者信息等配置"
echo ""

# 步骤 2
print_step "2" "安装开发工具"
print_command "./setup/01-install-tools.sh"
print_note "自动安装Rust、Solana CLI、Anchor框架"
echo ""

# 步骤 3
print_step "3" "设置开发钱包"
print_command "./setup/02-setup-wallet.sh --new"
print_note "创建新钱包并获取测试SOL"
echo ""

# 步骤 4
print_step "4" "创建Solana项目"
print_command "./project/03-create-project.sh --template counter"
print_note "创建一个计数器示例项目（推荐初学者）"
echo ""

# 步骤 5
print_step "5" "构建项目"
print_command "cd my_solana_project && ../development/05-build.sh --check-size"
print_note "编译程序并检查大小"
echo ""

# 步骤 6
print_step "6" "本地测试部署"
print_command "../deployment/08-deploy-local.sh --build"
print_note "启动本地验证器并部署程序"
echo ""

# 步骤 7
print_step "7" "部署到开发网"
print_command "../deployment/09-deploy-devnet.sh"
print_note "部署到Solana开发测试网"
echo ""

echo "========================================"
echo "🎓 学习建议："
echo ""
echo "1. 🔍 初次使用建议："
echo "   - 仔细阅读 '快速开始指南.md'"
echo "   - 逐步执行，不要跳过步骤"
echo "   - 遇到错误时查看错误信息"
echo ""

echo "2. 📚 常用命令："
echo "   - 检查工具状态: ./setup/01-install-tools.sh --check"
echo "   - 检查钱包状态: ./setup/02-setup-wallet.sh --check"
echo "   - 获取帮助信息: [脚本名] --help"
echo ""

echo "3. 🔧 故障排除："
echo "   - 验证配置: bash config/project-config.sh --validate"
echo "   - 查看日志: ls logs/"
echo "   - 重新开始: 删除项目目录后重新执行"
echo ""

echo "4. 📖 学习资源："
echo "   - Solana文档: https://docs.solana.com/"
echo "   - Anchor文档: https://anchor-lang.com/"
echo "   - Rust语言: https://doc.rust-lang.org/"
echo ""

echo "🎉 准备开始你的Solana开发之旅！"
echo ""
echo "⚠️ 重要提示："
echo "   - 这是示例脚本，请不要直接运行"
echo "   - 实际使用时请逐步执行每个命令"
echo "   - 首先修改配置文件中的项目信息"
echo ""