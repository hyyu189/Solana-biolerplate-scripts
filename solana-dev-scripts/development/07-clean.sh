#!/bin/bash

# ===================================================================
# Solana项目清理脚本
# 说明：清理构建产物和临时文件
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
    echo "Solana项目清理脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h          显示此帮助信息"
    echo "  --all               清理所有内容（包括依赖）"
    echo "  --deps              仅清理依赖"
    echo "  --build             仅清理构建产物"
    echo "  --test              仅清理测试数据"
    echo "  --logs              仅清理日志文件"
    echo "  --cache             清理缓存文件"
    echo "  --dry-run           显示将要清理的内容但不执行"
    echo ""
    echo "说明:"
    echo "  此脚本会清理项目的构建产物和临时文件"
    echo "  默认清理构建产物和测试数据，保留依赖"
}

# 检查是否在项目根目录
check_project_root() {
    if [ ! -f "Anchor.toml" ] && [ ! -f "Cargo.toml" ]; then
        print_color "red" "❌ 请在项目根目录下运行此脚本"
        print_color "blue" "提示：项目根目录应包含 Anchor.toml 或 Cargo.toml 文件"
        exit 1
    fi
}

# 计算目录大小
get_dir_size() {
    local dir="$1"
    if [ -d "$dir" ]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# 清理构建产物
clean_build_artifacts() {
    local dry_run="$1"
    
    print_color "blue" "🧹 清理构建产物..."
    
    local total_size=0
    
    # 清理target目录
    if [ -d "target" ]; then
        local size=$(get_dir_size "target")
        print_color "blue" "  - target/ ($size)"
        
        if [ "$dry_run" != true ]; then
            if [ -f "Anchor.toml" ]; then
                anchor clean
            else
                cargo clean
            fi
            print_color "green" "    ✅ 已清理"
        fi
    else
        print_color "yellow" "  ⏭️ target/ 不存在"
    fi
    
    # 清理.anchor目录
    if [ -d ".anchor" ]; then
        local size=$(get_dir_size ".anchor")
        print_color "blue" "  - .anchor/ ($size)"
        
        if [ "$dry_run" != true ]; then
            rm -rf .anchor/
            print_color "green" "    ✅ 已清理"
        fi
    fi
    
    print_color "green" "✅ 构建产物清理完成"
}

# 清理依赖
clean_dependencies() {
    local dry_run="$1"
    
    print_color "blue" "🧹 清理依赖..."
    
    # 清理Node.js依赖
    if [ -d "node_modules" ]; then
        local size=$(get_dir_size "node_modules")
        print_color "blue" "  - node_modules/ ($size)"
        
        if [ "$dry_run" != true ]; then
            rm -rf node_modules/
            print_color "green" "    ✅ 已清理"
        fi
    else
        print_color "yellow" "  ⏭️ node_modules/ 不存在"
    fi
    
    # 清理Cargo锁文件和缓存
    if [ -f "Cargo.lock" ]; then
        print_color "blue" "  - Cargo.lock"
        
        if [ "$dry_run" != true ]; then
            rm -f Cargo.lock
            print_color "green" "    ✅ 已清理"
        fi
    fi
    
    # 清理yarn锁文件
    if [ -f "yarn.lock" ]; then
        print_color "blue" "  - yarn.lock"
        
        if [ "$dry_run" != true ]; then
            rm -f yarn.lock
            print_color "green" "    ✅ 已清理"
        fi
    fi
    
    # 清理package-lock.json
    if [ -f "package-lock.json" ]; then
        print_color "blue" "  - package-lock.json"
        
        if [ "$dry_run" != true ]; then
            rm -f package-lock.json
            print_color "green" "    ✅ 已清理"
        fi
    fi
    
    print_color "green" "✅ 依赖清理完成"
}

# 清理测试数据
clean_test_data() {
    local dry_run="$1"
    
    print_color "blue" "🧹 清理测试数据..."
    
    # 清理test-ledger
    if [ -d "test-ledger" ]; then
        local size=$(get_dir_size "test-ledger")
        print_color "blue" "  - test-ledger/ ($size)"
        
        if [ "$dry_run" != true ]; then
            rm -rf test-ledger/
            print_color "green" "    ✅ 已清理"
        fi
    else
        print_color "yellow" "  ⏭️ test-ledger/ 不存在"
    fi
    
    # 清理覆盖率报告
    if [ -d "coverage" ]; then
        local size=$(get_dir_size "coverage")
        print_color "blue" "  - coverage/ ($size)"
        
        if [ "$dry_run" != true ]; then
            rm -rf coverage/
            print_color "green" "    ✅ 已清理"
        fi
    fi
    
    print_color "green" "✅ 测试数据清理完成"
}

# 清理日志文件
clean_logs() {
    local dry_run="$1"
    
    print_color "blue" "🧹 清理日志文件..."
    
    # 清理logs目录
    if [ -d "$LOG_DIR" ]; then
        local size=$(get_dir_size "$LOG_DIR")
        print_color "blue" "  - $LOG_DIR/ ($size)"
        
        if [ "$dry_run" != true ]; then
            # 只清理日志文件，保留目录
            find "$LOG_DIR" -type f -name "*.log" -delete 2>/dev/null
            find "$LOG_DIR" -type f -name "*.txt" -delete 2>/dev/null
            print_color "green" "    ✅ 已清理"
        fi
    else
        print_color "yellow" "  ⏭️ $LOG_DIR/ 不存在"
    fi
    
    # 清理其他日志文件
    if ls *.log >/dev/null 2>&1; then
        print_color "blue" "  - *.log 文件"
        
        if [ "$dry_run" != true ]; then
            rm -f *.log
            print_color "green" "    ✅ 已清理"
        fi
    fi
    
    print_color "green" "✅ 日志文件清理完成"
}

# 清理缓存
clean_cache() {
    local dry_run="$1"
    
    print_color "blue" "🧹 清理缓存..."
    
    # 清理Rust缓存
    if [ -d "$HOME/.cargo/registry" ]; then
        local size=$(get_dir_size "$HOME/.cargo/registry")
        print_color "blue" "  - Rust registry cache ($size)"
        
        if [ "$dry_run" != true ]; then
            print_color "yellow" "    ⚠️ 这会清理全局Rust缓存，可能影响其他项目"
            print_color "blue" "    是否继续? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                cargo cache -a
                print_color "green" "    ✅ 已清理"
            else
                print_color "yellow" "    ⏭️ 已跳过"
            fi
        fi
    fi
    
    # 清理临时文件
    if ls /tmp/solana-* >/dev/null 2>&1; then
        print_color "blue" "  - Solana临时文件"
        
        if [ "$dry_run" != true ]; then
            rm -rf /tmp/solana-* 2>/dev/null
            print_color "green" "    ✅ 已清理"
        fi
    fi
    
    print_color "green" "✅ 缓存清理完成"
}

# 清理所有内容
clean_all() {
    local dry_run="$1"
    
    print_color "blue" "🧹 清理所有内容..."
    echo ""
    
    clean_build_artifacts "$dry_run"
    echo ""
    
    clean_dependencies "$dry_run"
    echo ""
    
    clean_test_data "$dry_run"
    echo ""
    
    clean_logs "$dry_run"
    echo ""
    
    clean_cache "$dry_run"
}

# 显示清理摘要
show_summary() {
    print_color "blue" "📊 当前项目状态:"
    echo ""
    
    echo "构建产物:"
    if [ -d "target" ]; then
        echo "  - target/: $(get_dir_size 'target')"
    else
        echo "  - target/: 不存在"
    fi
    
    if [ -d ".anchor" ]; then
        echo "  - .anchor/: $(get_dir_size '.anchor')"
    else
        echo "  - .anchor/: 不存在"
    fi
    
    echo ""
    echo "依赖:"
    if [ -d "node_modules" ]; then
        echo "  - node_modules/: $(get_dir_size 'node_modules')"
    else
        echo "  - node_modules/: 不存在"
    fi
    
    echo ""
    echo "测试数据:"
    if [ -d "test-ledger" ]; then
        echo "  - test-ledger/: $(get_dir_size 'test-ledger')"
    else
        echo "  - test-ledger/: 不存在"
    fi
    
    if [ -d "coverage" ]; then
        echo "  - coverage/: $(get_dir_size 'coverage')"
    else
        echo "  - coverage/: 不存在"
    fi
    
    echo ""
    echo "日志:"
    if [ -d "$LOG_DIR" ]; then
        echo "  - $LOG_DIR/: $(get_dir_size "$LOG_DIR")"
    else
        echo "  - $LOG_DIR/: 不存在"
    fi
}

# 主清理流程
main_clean() {
    local clean_all_flag=false
    local clean_deps=false
    local clean_build=false
    local clean_test=false
    local clean_logs_flag=false
    local clean_cache_flag=false
    local dry_run=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --all)
                clean_all_flag=true
                shift
                ;;
            --deps)
                clean_deps=true
                shift
                ;;
            --build)
                clean_build=true
                shift
                ;;
            --test)
                clean_test=true
                shift
                ;;
            --logs)
                clean_logs_flag=true
                shift
                ;;
            --cache)
                clean_cache_flag=true
                shift
                ;;
            --dry-run)
                dry_run=true
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
    
    print_color "blue" "🚀 开始清理项目..."
    print_color "blue" "项目: $PROJECT_NAME"
    if [ "$dry_run" = true ]; then
        print_color "yellow" "模式: 预览模式（不会实际删除文件）"
    fi
    echo ""
    
    # 显示清理前状态
    show_summary
    echo ""
    
    # 根据参数执行清理
    if [ "$clean_all_flag" = true ]; then
        clean_all "$dry_run"
    else
        # 如果没有指定任何选项，默认清理构建和测试数据
        if [ "$clean_deps" = false ] && [ "$clean_build" = false ] && \
           [ "$clean_test" = false ] && [ "$clean_logs_flag" = false ] && \
           [ "$clean_cache_flag" = false ]; then
            clean_build=true
            clean_test=true
        fi
        
        if [ "$clean_build" = true ]; then
            clean_build_artifacts "$dry_run"
            echo ""
        fi
        
        if [ "$clean_deps" = true ]; then
            clean_dependencies "$dry_run"
            echo ""
        fi
        
        if [ "$clean_test" = true ]; then
            clean_test_data "$dry_run"
            echo ""
        fi
        
        if [ "$clean_logs_flag" = true ]; then
            clean_logs "$dry_run"
            echo ""
        fi
        
        if [ "$clean_cache_flag" = true ]; then
            clean_cache "$dry_run"
            echo ""
        fi
    fi
    
    # 显示清理后状态
    if [ "$dry_run" != true ]; then
        print_color "green" "🎉 清理完成！"
        echo ""
        show_summary
        
        echo ""
        print_color "blue" "📝 接下来可以："
        echo "  1. 重新构建: ../development/05-build.sh"
        if [ "$clean_deps" = true ] || [ "$clean_all_flag" = true ]; then
            echo "  2. 重新安装依赖: yarn install 或 npm install"
        fi
    else
        print_color "yellow" "这是预览模式，没有实际删除文件"
        print_color "blue" "要执行实际清理，请移除 --dry-run 参数"
    fi
}

# 执行主流程
main_clean "$@"
