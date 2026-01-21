#!/bin/bash

# ===================================================================
# Solana程序构建脚本
# 说明：构建Solana程序并检查构建结果
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
    echo "Solana程序构建脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h          显示此帮助信息"
    echo "  --clean, -c         构建前先清理"
    echo "  --release, -r       发布模式构建（注：Anchor默认使用release模式）"
    echo "  --program NAME      只构建指定程序"
    echo "  --verbose, -v       显示详细构建输出"
    echo "  --check-size        构建后检查程序大小"
    echo "  --jobs N           并行构建任务数（默认: $BUILD_JOBS）"
    echo ""
    echo "说明:"
    echo "  此脚本会构建项目中的所有Solana程序"
    echo "  Anchor项目默认使用release模式构建（已优化）"
    echo "  构建成功后会自动检查程序大小和基本信息"
}

# 检查是否在项目根目录
check_project_root() {
    if [ ! -f "Anchor.toml" ] && [ ! -f "Cargo.toml" ]; then
        print_color "red" "❌ 请在项目根目录下运行此脚本"
        print_color "blue" "提示：项目根目录应包含 Anchor.toml 或 Cargo.toml 文件"
        exit 1
    fi
}

# 清理构建产物
clean_build() {
    print_color "blue" "🧹 清理构建产物..."
    
    if [ -f "Anchor.toml" ]; then
        anchor clean
    else
        cargo clean
    fi
    
    # 清理测试网络数据
    if [ -d "test-ledger" ]; then
        rm -rf test-ledger/
        print_color "green" "✅ 清理测试网络数据"
    fi
    
    print_color "green" "✅ 清理完成"
}

# 构建程序
build_programs() {
    local build_mode="$1"
    local specific_program="$2"
    local verbose="$3"
    local jobs="$4"
    
    print_color "blue" "🔨 开始构建程序..."
    
    local start_time=$(date +%s)
    local build_success=true
    
    if [ -f "Anchor.toml" ]; then
        # 使用Anchor构建
        print_color "blue" "使用Anchor框架构建..."
        
        # 注意：Anchor默认使用release模式构建，不需要--release参数
        local cmd="anchor build"
        
        if [ -n "$specific_program" ]; then
            cmd="$cmd --program-name $specific_program"
        fi
        
        if [ "$verbose" = true ]; then
            cmd="$cmd --verbose"
        fi
        
        # 设置并行构建
        if [ -n "$jobs" ]; then
            export CARGO_BUILD_JOBS="$jobs"
        fi
        
        # 如果指定了release模式，通过CARGO参数传递
        if [ "$build_mode" = "release" ]; then
            # Anchor默认就是release模式，这里只是为了显式说明
            print_color "blue" "构建模式: release (Anchor默认)"
        fi
        
        # 执行构建
        if eval $cmd; then
            print_color "green" "✅ Anchor构建成功"
        else
            print_color "red" "❌ Anchor构建失败"
            build_success=false
        fi
        
    elif [ -f "Cargo.toml" ]; then
        # 使用Cargo构建
        print_color "blue" "使用Cargo构建..."
        
        local cmd="cargo build-sbf"
        
        if [ "$build_mode" = "release" ]; then
            cmd="$cmd --release"
        fi
        
        if [ "$verbose" = true ]; then
            cmd="$cmd --verbose"
        fi
        
        # 设置并行构建
        if [ -n "$jobs" ]; then
            cmd="$cmd --jobs $jobs"
        fi
        
        # 执行构建
        if eval $cmd; then
            print_color "green" "✅ Cargo构建成功"
        else
            print_color "red" "❌ Cargo构建失败"
            build_success=false
        fi
    else
        print_color "red" "❌ 未找到有效的构建配置文件"
        return 1
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ "$build_success" = true ]; then
        print_color "green" "✅ 构建完成，耗时: ${duration}秒"
        return 0
    else
        print_color "red" "❌ 构建失败，耗时: ${duration}秒"
        return 1
    fi
}

# 检查程序大小和信息
check_program_info() {
    print_color "blue" "📊 检查程序信息..."
    
    # 查找构建产物
    local deploy_dir="./target/deploy"
    
    if [ ! -d "$deploy_dir" ]; then
        print_color "yellow" "⚠️ 未找到构建产物目录: $deploy_dir"
        return 1
    fi
    
    local so_files=($(find "$deploy_dir" -name "*.so" 2>/dev/null))
    
    if [ ${#so_files[@]} -eq 0 ]; then
        print_color "yellow" "⚠️ 未找到程序文件 (.so)"
        return 1
    fi
    
    echo ""
    print_color "blue" "📋 程序信息:"
    echo "=================================================="
    
    for so_file in "${so_files[@]}"; do
        local program_name=$(basename "$so_file" .so)
        local file_size=$(stat -f%z "$so_file" 2>/dev/null || stat -c%s "$so_file" 2>/dev/null || echo "unknown")
        local file_size_kb=$((file_size / 1024))
        local file_size_mb=$((file_size / 1024 / 1024))
        
        echo ""
        print_color "purple" "程序名称: $program_name"
        echo "文件路径: $so_file"
        echo "文件大小: $file_size bytes ($file_size_kb KB)"
        
        # 检查程序大小限制
        if [ "$file_size" -gt "$MAX_PROGRAM_SIZE" ]; then
            local max_size_mb=$((MAX_PROGRAM_SIZE / 1024 / 1024))
            print_color "red" "⚠️ 警告：程序大小超过限制 ($max_size_mb MB)"
        else
            print_color "green" "✅ 程序大小符合要求"
        fi
        
        # 显示文件类型信息
        if command -v file >/dev/null 2>&1; then
            local file_type=$(file "$so_file")
            echo "文件类型: $file_type"
        fi
        
        # 查找对应的密钥对文件
        local keypair_file="${so_file%.so}-keypair.json"
        if [ -f "$keypair_file" ]; then
            print_color "green" "✅ 找到密钥对文件: $keypair_file"
            
            # 显示程序ID
            if command -v solana >/dev/null 2>&1; then
                local program_id=$(solana address -k "$keypair_file" 2>/dev/null)
                if [ $? -eq 0 ] && [ -n "$program_id" ]; then
                    echo "程序ID: $program_id"
                fi
            fi
        else
            print_color "yellow" "⚠️ 未找到密钥对文件: $keypair_file"
        fi
        
        echo "--------------------------------------------------"
    done
    
    echo ""
    print_color "green" "✅ 程序信息检查完成"
}

# 生成构建报告
generate_build_report() {
    print_color "blue" "📄 生成构建报告..."
    
    local report_file="$LOG_DIR/build-report-$(date +%Y%m%d-%H%M%S).txt"
    
    # 确保日志目录存在
    mkdir -p "$LOG_DIR"
    
    # 生成报告内容
    {
        echo "==============================================="
        echo "Solana程序构建报告"
        echo "==============================================="
        echo "构建时间: $(date)"
        echo "项目名称: $PROJECT_NAME"
        echo "构建模式: $BUILD_OPTIMIZATION"
        echo ""
        echo "环境信息:"
        echo "Solana版本: $(solana --version 2>/dev/null || echo '未安装')"
        echo "Anchor版本: $(anchor --version 2>/dev/null || echo '未安装')"
        echo "Rust版本: $(rustc --version 2>/dev/null || echo '未安装')"
        echo ""
        echo "程序列表:"
        
        if [ -d "./target/deploy" ]; then
            find "./target/deploy" -name "*.so" -exec basename {} .so \; | sort
        else
            echo "无程序文件"
        fi
        
        echo ""
        echo "构建产物大小:"
        if [ -d "./target/deploy" ]; then
            du -sh ./target/deploy/*.so 2>/dev/null || echo "无程序文件"
        fi
        
    } > "$report_file"
    
    print_color "green" "✅ 构建报告已保存: $report_file"
}

# 主构建流程
main_build() {
    local clean_before=false
    local build_mode="$BUILD_OPTIMIZATION"
    local specific_program=""
    local verbose=false
    local check_size=false
    local jobs="$BUILD_JOBS"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --clean|-c)
                clean_before=true
                shift
                ;;
            --release|-r)
                build_mode="release"
                shift
                ;;
            --program)
                specific_program="$2"
                shift 2
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --check-size)
                check_size=true
                shift
                ;;
            --jobs)
                jobs="$2"
                shift 2
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
    
    print_color "blue" "🚀 开始构建Solana程序..."
    print_color "blue" "项目: $PROJECT_NAME"
    print_color "blue" "模式: $build_mode"
    if [ -n "$specific_program" ]; then
        print_color "blue" "程序: $specific_program"
    fi
    echo ""
    
    # 清理（如果需要）
    if [ "$clean_before" = true ]; then
        clean_build
        echo ""
    fi
    
    # 构建程序
    if build_programs "$build_mode" "$specific_program" "$verbose" "$jobs"; then
        echo ""
        
        # 检查程序信息
        if [ "$check_size" = true ]; then
            check_program_info
            echo ""
        fi
        
        # 生成构建报告
        generate_build_report
        
        echo ""
        print_color "green" "🎉 构建流程完成！"
        
        # 显示下一步提示
        print_color "blue" "📝 接下来可以："
        echo "  1. 运行测试: ./development/06-test.sh"
        echo "  2. 本地部署: ./deployment/08-deploy-local.sh"
        echo "  3. 部署到devnet: ./deployment/09-deploy-devnet.sh"
        
    else
        print_color "red" "❌ 构建失败"
        exit 1
    fi
}

# 执行主流程
main_build "$@"