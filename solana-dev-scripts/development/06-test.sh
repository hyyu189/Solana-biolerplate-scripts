#!/bin/bash

# ===================================================================
# Solana程序测试脚本
# 说明：运行Solana程序测试并生成测试报告
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
    echo "Solana程序测试脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h          显示此帮助信息"
    echo "  --unit              仅运行Rust单元测试"
    echo "  --integration       仅运行集成测试"
    echo "  --skip-build        跳过构建步骤"
    echo "  --skip-deploy       跳过部署步骤"
    echo "  --verbose, -v       显示详细测试输出"
    echo "  --coverage          生成测试覆盖率报告"
    echo "  --localnet          使用本地测试网络"
    echo "  --file FILE         运行特定测试文件"
    echo ""
    echo "说明:"
    echo "  此脚本会运行项目的所有测试"
    echo "  包括Rust单元测试和JavaScript/TypeScript集成测试"
}

# 检查是否在项目根目录
check_project_root() {
    if [ ! -f "Anchor.toml" ] && [ ! -f "Cargo.toml" ]; then
        print_color "red" "❌ 请在项目根目录下运行此脚本"
        print_color "blue" "提示：项目根目录应包含 Anchor.toml 或 Cargo.toml 文件"
        exit 1
    fi
}

# 运行Rust单元测试
run_unit_tests() {
    local verbose="$1"
    
    print_color "blue" "🧪 运行Rust单元测试..."
    
    local cmd="cargo test"
    
    if [ "$verbose" = true ]; then
        cmd="$cmd --verbose"
    fi
    
    # 添加显示输出选项
    cmd="$cmd -- --show-output"
    
    local start_time=$(date +%s)
    
    if eval $cmd; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_color "green" "✅ 单元测试通过，耗时: ${duration}秒"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_color "red" "❌ 单元测试失败，耗时: ${duration}秒"
        return 1
    fi
}

# 运行集成测试
run_integration_tests() {
    local skip_build="$1"
    local skip_deploy="$2"
    local verbose="$3"
    local test_file="$4"
    local use_localnet="$5"
    
    print_color "blue" "🧪 运行集成测试..."
    
    if [ ! -f "Anchor.toml" ]; then
        print_color "yellow" "⚠️ 未找到Anchor.toml，跳过集成测试"
        return 0
    fi
    
    local cmd="anchor test"
    
    # 添加选项
    if [ "$skip_build" = true ]; then
        cmd="$cmd --skip-build"
    fi
    
    if [ "$skip_deploy" = true ]; then
        cmd="$cmd --skip-deploy"
    fi
    
    if [ "$use_localnet" = true ]; then
        cmd="$cmd --provider.cluster localnet"
    fi
    
    if [ -n "$test_file" ]; then
        cmd="$cmd $test_file"
    fi
    
    local start_time=$(date +%s)
    
    if eval $cmd; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_color "green" "✅ 集成测试通过，耗时: ${duration}秒"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_color "red" "❌ 集成测试失败，耗时: ${duration}秒"
        return 1
    fi
}

# 生成测试覆盖率报告
generate_coverage() {
    print_color "blue" "📊 生成测试覆盖率报告..."
    
    # 检查是否安装了cargo-tarpaulin
    if ! command -v cargo-tarpaulin &> /dev/null; then
        print_color "yellow" "⚠️ cargo-tarpaulin未安装"
        print_color "blue" "正在安装cargo-tarpaulin..."
        
        if cargo install cargo-tarpaulin; then
            print_color "green" "✅ cargo-tarpaulin安装成功"
        else
            print_color "red" "❌ cargo-tarpaulin安装失败"
            return 1
        fi
    fi
    
    # 创建覆盖率报告目录
    mkdir -p coverage
    
    # 生成覆盖率报告
    print_color "blue" "正在生成覆盖率报告..."
    
    if cargo tarpaulin --out Html --output-dir coverage/; then
        print_color "green" "✅ 覆盖率报告生成成功"
        print_color "blue" "报告位置: coverage/index.html"
        
        # 如果在macOS上，尝试打开报告
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open coverage/index.html 2>/dev/null || true
        fi
    else
        print_color "red" "❌ 覆盖率报告生成失败"
        return 1
    fi
}

# 生成测试报告
generate_test_report() {
    print_color "blue" "📄 生成测试报告..."
    
    local report_file="$LOG_DIR/test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    # 确保日志目录存在
    mkdir -p "$LOG_DIR"
    
    # 生成报告内容
    {
        echo "==============================================="
        echo "Solana程序测试报告"
        echo "==============================================="
        echo "测试时间: $(date)"
        echo "项目名称: $PROJECT_NAME"
        echo ""
        echo "环境信息:"
        echo "Solana版本: $(solana --version 2>/dev/null || echo '未安装')"
        echo "Anchor版本: $(anchor --version 2>/dev/null || echo '未安装')"
        echo "Rust版本: $(rustc --version 2>/dev/null || echo '未安装')"
        echo "Node版本: $(node --version 2>/dev/null || echo '未安装')"
        echo ""
        echo "测试配置:"
        echo "测试网络: $TEST_NETWORK"
        echo "详细输出: $VERBOSE_TESTS"
        echo ""
        
        # 列出测试文件
        echo "测试文件:"
        if [ -d "tests" ]; then
            find tests -name "*.ts" -o -name "*.js" 2>/dev/null | sort
        else
            echo "无测试文件"
        fi
        
        echo ""
        echo "Rust单元测试:"
        cargo test --no-run 2>&1 | grep "Running" || echo "无单元测试"
        
    } > "$report_file"
    
    print_color "green" "✅ 测试报告已保存: $report_file"
}

# 检查测试环境
check_test_environment() {
    print_color "blue" "🔍 检查测试环境..."
    
    local all_ok=true
    
    # 检查测试文件是否存在
    if [ -d "tests" ]; then
        local test_count=$(find tests -name "*.ts" -o -name "*.js" 2>/dev/null | wc -l)
        if [ "$test_count" -gt 0 ]; then
            print_color "green" "✅ 找到 $test_count 个测试文件"
        else
            print_color "yellow" "⚠️ 测试目录存在但没有测试文件"
        fi
    else
        print_color "yellow" "⚠️ 测试目录不存在"
        all_ok=false
    fi
    
    # 检查程序是否已构建
    if [ -d "target/deploy" ] && ls target/deploy/*.so >/dev/null 2>&1; then
        print_color "green" "✅ 程序已构建"
    else
        print_color "yellow" "⚠️ 程序未构建，测试前需要先构建"
        all_ok=false
    fi
    
    # 检查Node.js依赖
    if [ -f "package.json" ]; then
        if [ -d "node_modules" ]; then
            print_color "green" "✅ Node.js依赖已安装"
        else
            print_color "yellow" "⚠️ Node.js依赖未安装"
            all_ok=false
        fi
    fi
    
    # 检查网络连接（如果需要）
    if [ "$AUTO_START_VALIDATOR" = true ]; then
        if pgrep -f "solana-test-validator" > /dev/null; then
            print_color "green" "✅ 本地验证器正在运行"
        else
            print_color "yellow" "⚠️ 本地验证器未运行，将自动启动"
        fi
    fi
    
    echo ""
    if [ "$all_ok" = false ]; then
        print_color "yellow" "⚠️ 测试环境存在问题，但可以继续运行"
    fi
}

# 启动本地验证器（如果需要）
start_validator_if_needed() {
    if [ "$AUTO_START_VALIDATOR" != true ]; then
        return 0
    fi
    
    # 检查验证器是否已经运行
    if pgrep -f "solana-test-validator" > /dev/null; then
        print_color "green" "✅ 本地验证器已在运行"
        return 0
    fi
    
    print_color "blue" "🚀 启动本地验证器..."
    
    # 确保日志目录存在
    mkdir -p "$LOG_DIR"
    
    # 启动验证器
    nohup solana-test-validator --reset --quiet > "$LOG_DIR/validator.log" 2>&1 &
    
    # 等待验证器启动
    local max_wait=30
    local wait_count=0
    
    print_color "blue" "等待验证器启动..."
    while [ $wait_count -lt $max_wait ]; do
        if solana cluster-version >/dev/null 2>&1; then
            print_color "green" "✅ 验证器启动成功"
            return 0
        fi
        
        echo -n "."
        sleep 1
        wait_count=$((wait_count + 1))
    done
    
    echo ""
    print_color "red" "❌ 验证器启动超时"
    return 1
}

# 主测试流程
main_test() {
    local unit_only=false
    local integration_only=false
    local skip_build=false
    local skip_deploy=false
    local verbose="$VERBOSE_TESTS"
    local coverage=false
    local use_localnet=false
    local test_file=""
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --unit)
                unit_only=true
                shift
                ;;
            --integration)
                integration_only=true
                shift
                ;;
            --skip-build)
                skip_build=true
                shift
                ;;
            --skip-deploy)
                skip_deploy=true
                shift
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --coverage)
                coverage=true
                shift
                ;;
            --localnet)
                use_localnet=true
                shift
                ;;
            --file)
                test_file="$2"
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
    
    print_color "blue" "🚀 开始测试Solana程序..."
    print_color "blue" "项目: $PROJECT_NAME"
    if [ -n "$test_file" ]; then
        print_color "blue" "测试文件: $test_file"
    fi
    echo ""
    
    # 检查测试环境
    check_test_environment
    echo ""
    
    # 启动本地验证器（如果需要）
    if [ "$integration_only" = false ] || [ "$use_localnet" = true ]; then
        start_validator_if_needed
        echo ""
    fi
    
    local test_success=true
    
    # 运行单元测试
    if [ "$integration_only" = false ]; then
        if ! run_unit_tests "$verbose"; then
            test_success=false
        fi
        echo ""
    fi
    
    # 运行集成测试
    if [ "$unit_only" = false ]; then
        if ! run_integration_tests "$skip_build" "$skip_deploy" "$verbose" "$test_file" "$use_localnet"; then
            test_success=false
        fi
        echo ""
    fi
    
    # 生成覆盖率报告
    if [ "$coverage" = true ]; then
        generate_coverage
        echo ""
    fi
    
    # 生成测试报告
    generate_test_report
    
    # 显示测试结果
    echo ""
    if [ "$test_success" = true ]; then
        print_color "green" "🎉 所有测试通过！"
        
        echo ""
        print_color "blue" "📝 接下来可以："
        echo "  1. 本地部署: ../deployment/08-deploy-local.sh"
        echo "  2. 部署到devnet: ../deployment/09-deploy-devnet.sh"
        echo "  3. 查看覆盖率: $0 --coverage"
        
        exit 0
    else
        print_color "red" "❌ 测试失败"
        
        echo ""
        print_color "blue" "💡 故障排除："
        echo "  1. 检查错误信息和日志"
        echo "  2. 确保程序已正确构建: ../development/05-build.sh"
        echo "  3. 运行详细测试: $0 --verbose"
        echo "  4. 检查测试代码和程序逻辑"
        
        exit 1
    fi
}

# 执行主流程
main_test "$@"
