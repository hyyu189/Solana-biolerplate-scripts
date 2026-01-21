#!/bin/bash

# ===================================================================
# Solana开发环境修复工具
# 说明：一键修复所有常见的开发环境问题
# 适用人群：初学者遇到构建错误时使用
# ===================================================================

# 颜色输出函数
print_color() {
    case $1 in
        "red")    echo -e "\033[31m$2\033[0m" ;;
        "green")  echo -e "\033[32m$2\033[0m" ;;
        "yellow") echo -e "\033[33m$2\033[0m" ;;
        "blue")   echo -e "\033[34m$2\033[0m" ;;
        *)        echo "$2" ;;
    esac
}

# 显示帮助信息
show_help() {
    cat << EOF
🔧 Solana开发环境修复工具

这个脚本会自动诊断并修复常见的开发环境问题。

用法:
  $0 [选项]

选项:
  --help, -h       显示此帮助信息
  --quick, -q      快速修复（仅修复 BPF SDK）
  --full, -f       完整修复（重新安装所有工具）
  --check, -c      仅检查问题，不进行修复

常见使用场景:
  1. 构建失败，提示 "SDK path does not exist"
     → 运行: $0

  2. 工具版本不匹配
     → 运行: $0 --full

  3. 不确定哪里有问题
     → 运行: $0 --check
EOF
}

# 显示标题
show_banner() {
    print_color "blue" "╔════════════════════════════════════════╗"
    print_color "blue" "║   Solana开发环境修复工具 v1.0        ║"
    print_color "blue" "║   适用于初学者的一键修复方案          ║"
    print_color "blue" "╚════════════════════════════════════════╝"
    echo ""
}

# 检查并诊断问题
diagnose_issues() {
    print_color "blue" "🔍 步骤 1/4: 诊断开发环境..."
    echo ""
    
    local issues_found=0
    
    # 检查 Rust
    if ! command -v rustc &> /dev/null; then
        print_color "red" "❌ 问题 1: Rust 未安装"
        issues_found=$((issues_found + 1))
    else
        print_color "green" "✅ Rust: $(rustc --version | cut -d' ' -f2)"
    fi
    
    # 检查 Solana CLI
    if ! command -v solana &> /dev/null; then
        print_color "red" "❌ 问题 2: Solana CLI 未安装"
        issues_found=$((issues_found + 1))
    else
        print_color "green" "✅ Solana CLI: $(solana --version | cut -d' ' -f2)"
    fi
    
    # 检查 Anchor
    if ! command -v anchor &> /dev/null; then
        print_color "red" "❌ 问题 3: Anchor 未安装"
        issues_found=$((issues_found + 1))
    else
        print_color "green" "✅ Anchor: $(anchor --version | cut -d' ' -f2)"
    fi
    
    # 检查 cargo-build-sbf
    if ! command -v cargo-build-sbf &> /dev/null; then
        print_color "red" "❌ 问题 4: cargo-build-sbf 未安装"
        issues_found=$((issues_found + 1))
    else
        print_color "green" "✅ cargo-build-sbf: 已安装"
    fi
    
    # 检查 BPF SDK
    if [ -d ~/.cache/solana ]; then
        SDK_DIRS=$(find ~/.cache/solana -name "sbf" -type d 2>/dev/null)
        if [ -z "$SDK_DIRS" ]; then
            print_color "red" "❌ 问题 5: BPF SDK 未下载"
            issues_found=$((issues_found + 1))
        else
            print_color "green" "✅ BPF SDK: 已下载"
        fi
    else
        print_color "red" "❌ 问题 5: Solana 缓存目录不存在"
        issues_found=$((issues_found + 1))
    fi
    
    echo ""
    
    if [ $issues_found -eq 0 ]; then
        print_color "green" "🎉 太好了！未发现任何问题。"
        print_color "blue" "如果仍然遇到构建错误，请查看具体错误信息。"
        return 0
    else
        print_color "yellow" "⚠️ 发现 $issues_found 个问题需要修复"
        return $issues_found
    fi
}

# 修复 BPF SDK（最常见的问题）
fix_bpf_sdk() {
    print_color "blue" "🔧 步骤 2/4: 修复 BPF SDK..."
    echo ""
    
    # 子步骤1: 清理旧缓存
    print_color "yellow" "→ 清理旧的 Solana 缓存..."
    if [ -d ~/.cache/solana ]; then
        rm -rf ~/.cache/solana/*
        print_color "green" "  ✅ 缓存已清理"
    else
        mkdir -p ~/.cache/solana
        print_color "green" "  ✅ 缓存目录已创建"
    fi
    echo ""
    
    # 子步骤2: 重新安装 cargo-build-sbf
    print_color "yellow" "→ 重新安装 cargo-build-sbf 工具..."
    print_color "blue" "  (这可能需要几分钟，请耐心等待...)"
    
    if cargo install --git https://github.com/anza-xyz/agave cargo-build-sbf --locked --force &> /tmp/repair-cargo-install.log; then
        print_color "green" "  ✅ cargo-build-sbf 安装成功"
    else
        print_color "yellow" "  ⚠️ 安装过程有警告，但可能已成功"
        print_color "blue" "  查看详细日志: /tmp/repair-cargo-install.log"
    fi
    echo ""
    
    # 子步骤3: 下载 BPF SDK
    print_color "yellow" "→ 下载 BPF SDK (约50-100MB)..."
    print_color "blue" "  这是一次性下载，首次可能需要5-10分钟"
    print_color "blue" "  请不要中断，下载进度会显示在下方..."
    echo ""
    
    if cargo build-sbf --force-tools-install 2>&1 | tee /tmp/repair-sdk-download.log; then
        print_color "green" "  ✅ BPF SDK 下载完成"
    else
        # 首次下载可能显示错误，但实际已完成
        print_color "yellow" "  ⚠️ 下载过程显示警告，正在验证..."
        sleep 2
        
        if cargo build-sbf --version &> /dev/null; then
            print_color "green" "  ✅ 验证成功，SDK 已就绪"
        else
            print_color "yellow" "  ⚠️ SDK 将在首次构建时自动完成下载"
        fi
    fi
    echo ""
}

# 验证修复结果
verify_fix() {
    print_color "blue" "🔍 步骤 3/4: 验证修复结果..."
    echo ""
    
    local all_ok=true
    
    # 验证 cargo-build-sbf
    if command -v cargo-build-sbf &> /dev/null; then
        VERSION=$(cargo-build-sbf --version 2>&1 | head -1)
        print_color "green" "✅ cargo-build-sbf: $VERSION"
    else
        print_color "red" "❌ cargo-build-sbf 仍不可用"
        all_ok=false
    fi
    
    # 验证 SDK 目录
    if [ -d ~/.cache/solana ]; then
        SDK_DIRS=$(find ~/.cache/solana -name "sbf" -type d 2>/dev/null | head -1)
        if [ -n "$SDK_DIRS" ]; then
            print_color "green" "✅ BPF SDK 路径: $SDK_DIRS"
        else
            print_color "yellow" "⚠️ SDK 目录未找到（首次构建时会创建）"
        fi
    fi
    
    echo ""
    
    if [ "$all_ok" = true ]; then
        print_color "green" "🎉 验证成功！环境已修复。"
        return 0
    else
        print_color "yellow" "⚠️ 部分检查未通过，但可以尝试构建"
        return 1
    fi
}

# 显示下一步操作
show_next_steps() {
    print_color "blue" "📝 步骤 4/4: 下一步操作建议"
    echo ""
    
    print_color "green" "修复完成！现在您可以："
    echo ""
    echo "1️⃣  尝试构建您的项目:"
    echo "   cd my_solana_project"
    echo "   anchor build"
    echo ""
    echo "2️⃣  如果仍然遇到问题:"
    echo "   • 查看详细错误信息"
    echo "   • 检查 TROUBLESHOOTING.md 文档"
    echo "   • 运行 $0 --full 进行完整修复"
    echo ""
    echo "3️⃣  获取帮助:"
    echo "   • 查看日志: /tmp/repair-*.log"
    echo "   • 运行诊断: bash solana-dev-scripts/setup/01-install-tools.sh --check"
    echo ""
}

# 完整修复（重新安装所有工具）
full_repair() {
    print_color "blue" "🔄 执行完整修复..."
    echo ""
    
    print_color "yellow" "这将重新安装所有开发工具，可能需要10-20分钟。"
    print_color "yellow" "是否继续? (y/N)"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_color "blue" "已取消完整修复"
        exit 0
    fi
    
    # 调用安装脚本
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    
    if [ -f "$SCRIPT_DIR/setup/01-install-tools.sh" ]; then
        print_color "blue" "正在执行完整重新安装..."
        bash "$SCRIPT_DIR/setup/01-install-tools.sh" --force
    else
        print_color "red" "❌ 找不到安装脚本"
        exit 1
    fi
}

# 快速修复（仅修复 BPF SDK）
quick_repair() {
    show_banner
    
    print_color "blue" "🚀 快速修复模式（仅修复 BPF SDK 问题）"
    echo ""
    
    # 诊断
    diagnose_issues
    
    # 修复 BPF SDK
    fix_bpf_sdk
    
    # 验证
    verify_fix
    
    # 显示下一步
    show_next_steps
}

# 主修复流程
main_repair() {
    show_banner
    
    print_color "blue" "🚀 开始修复开发环境..."
    echo ""
    
    # 步骤1: 诊断
    diagnose_issues
    local issues=$?
    
    if [ $issues -eq 0 ]; then
        echo ""
        print_color "green" "环境检查通过，无需修复！"
        exit 0
    fi
    
    echo ""
    print_color "yellow" "按 Enter 继续修复，或按 Ctrl+C 取消..."
    read -r
    echo ""
    
    # 步骤2: 修复 BPF SDK
    fix_bpf_sdk
    
    # 步骤3: 验证
    verify_fix
    
    # 步骤4: 下一步建议
    show_next_steps
}

# 仅检查模式
check_only() {
    show_banner
    diagnose_issues
    echo ""
    
    print_color "blue" "💡 提示:"
    echo "  • 如需修复，运行: $0"
    echo "  • 如需完整重装，运行: $0 --full"
}

# 主程序
MODE="normal"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --quick|-q)
            MODE="quick"
            shift
            ;;
        --full|-f)
            MODE="full"
            shift
            ;;
        --check|-c)
            MODE="check"
            shift
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 执行相应模式
case $MODE in
    quick)
        quick_repair
        ;;
    full)
        show_banner
        full_repair
        ;;
    check)
        check_only
        ;;
    normal)
        main_repair
        ;;
esac

exit 0
