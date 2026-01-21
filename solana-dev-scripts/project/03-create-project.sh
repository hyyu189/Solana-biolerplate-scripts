#!/bin/bash

# ===================================================================
# Solana项目创建脚本
# 说明：创建新的Solana项目并设置基础结构
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
    echo "Solana项目创建脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项] [项目名称]"
    echo ""
    echo "选项:"
    echo "  --help, -h          显示此帮助信息"
    echo "  --template TYPE     使用指定模板创建项目"
    echo "                      可选: basic, counter, token, nft"
    echo "  --workspace DIR     在指定目录创建项目"
    echo "  --no-git           不初始化Git仓库"
    echo ""
    echo "说明:"
    echo "  如果不指定项目名称，将使用配置文件中的项目名称"
    echo "  项目会创建在当前目录的子目录中"
}

# 检查必要工具
check_tools() {
    local tools_missing=false
    
    if ! command -v anchor &> /dev/null; then
        print_color "red" "❌ Anchor框架未安装"
        tools_missing=true
    fi
    
    if ! command -v solana &> /dev/null; then
        print_color "red" "❌ Solana CLI未安装"
        tools_missing=true
    fi
    
    if [ "$tools_missing" = true ]; then
        print_color "blue" "请先运行: ./setup/01-install-tools.sh"
        exit 1
    fi
}

# 创建Anchor项目
create_anchor_project() {
    local project_name="$1"
    local project_dir="$2"
    
    print_color "blue" "📁 创建Anchor项目: $project_name"
    
    # 创建项目
    if anchor init "$project_name" --javascript; then
        print_color "green" "✅ Anchor项目创建成功"
        
        # 进入项目目录
        cd "$project_name"
        
        # 生成程序密钥对
        print_color "blue" "🔑 生成程序密钥对..."
        mkdir -p target/deploy
        solana-keygen new -o "target/deploy/${project_name}-keypair.json" --no-bip39-passphrase
        
        # 获取程序ID
        local program_id=$(solana address -k "target/deploy/${project_name}-keypair.json")
        print_color "green" "📍 程序ID: $program_id"
        
        # 更新Anchor.toml
        print_color "blue" "📝 更新Anchor.toml配置..."
        
        # 检查是否已经存在该程序的配置
        if ! grep -q "^$project_name = " Anchor.toml; then
            # 使用更安全的方式更新配置
            # 在[programs.localnet]下添加程序ID
            sed -i.bak "/\[programs\.localnet\]/a\\
$project_name = \"$program_id\"
" Anchor.toml
        fi
        
        # 更新默认集群配置
        sed -i.bak "s/cluster = \"localnet\"/cluster = \"$DEFAULT_NETWORK\"/" Anchor.toml
        
        # 清理备份文件
        rm -f Anchor.toml.bak
        
        print_color "green" "✅ 配置文件更新完成"
        
    else
        print_color "red" "❌ 项目创建失败"
        exit 1
    fi
}

# 创建项目模板
create_template_files() {
    local template_type="$1"
    local project_name="$2"
    
    print_color "blue" "📄 创建项目模板文件..."
    
    # 创建开发脚本目录
    mkdir -p scripts
    
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
    
    # 创建README
    cat > README.md << EOF
# $project_name

$PROJECT_DESCRIPTION

## 快速开始

### 安装依赖
\`\`\`bash
yarn install
\`\`\`

### 构建项目
\`\`\`bash
./scripts/build.sh
\`\`\`

### 运行测试
\`\`\`bash
./scripts/test.sh
\`\`\`

### 部署程序

#### 部署到开发网
\`\`\`bash
./scripts/deploy.sh devnet
\`\`\`

#### 部署到本地网络
\`\`\`bash
./scripts/deploy.sh localnet
\`\`\`

## 项目结构

\`\`\`
$project_name/
├── programs/               # Solana程序源码
│   └── $project_name/
├── tests/                 # 测试文件
├── app/                   # 前端应用（可选）
├── scripts/               # 开发脚本
├── target/                # 编译产物
├── Anchor.toml           # Anchor配置
├── Cargo.toml            # Rust包管理
└── package.json          # Node.js依赖
\`\`\`

## 开发指南

### 1. 修改程序逻辑
编辑 \`programs/$project_name/src/lib.rs\`

### 2. 编写测试
编辑 \`tests/$project_name.ts\`

### 3. 部署前检查
- 确保钱包有足够的SOL余额
- 检查程序大小是否符合限制
- 运行测试确保代码正确

## 作者

$DEVELOPER_NAME <$DEVELOPER_EMAIL>

## 许可证

MIT License
EOF

    # 根据模板类型创建特定文件
    case "$template_type" in
        "counter")
            create_counter_template "$project_name"
            ;;
        "token")
            create_token_template "$project_name"
            ;;
        "nft")
            create_nft_template "$project_name"
            ;;
        *)
            print_color "blue" "使用基础模板"
            ;;
    esac
    
    print_color "green" "✅ 项目模板文件创建完成"
}

# 创建计数器程序模板
create_counter_template() {
    local project_name="$1"
    
    print_color "blue" "📝 创建计数器程序模板..."
    
    # 创建计数器程序代码
    cat > "programs/$project_name/src/lib.rs" << 'EOF'
use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod counter_program {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        counter.count = 0;
        msg!("计数器已初始化，初始值: {}", counter.count);
        Ok(())
    }

    pub fn increment(ctx: Context<Increment>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        counter.count += 1;
        msg!("计数器递增，当前值: {}", counter.count);
        Ok(())
    }

    pub fn decrement(ctx: Context<Decrement>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        if counter.count > 0 {
            counter.count -= 1;
        }
        msg!("计数器递减，当前值: {}", counter.count);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(init, payer = user, space = 8 + 8)]
    pub counter: Account<'info, Counter>,
    #[account(mut)]
    pub user: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct Increment<'info> {
    #[account(mut)]
    pub counter: Account<'info, Counter>,
}

#[derive(Accounts)]
pub struct Decrement<'info> {
    #[account(mut)]
    pub counter: Account<'info, Counter>,
}

#[account]
pub struct Counter {
    pub count: u64,
}
EOF

    print_color "green" "✅ 计数器程序模板创建完成"
}

# 创建Git仓库
init_git() {
    local no_git="$1"
    
    if [ "$no_git" = true ]; then
        print_color "yellow" "⏭️ 跳过Git仓库初始化"
        return 0
    fi
    
    if ! command -v git &> /dev/null; then
        print_color "yellow" "⚠️ Git未安装，跳过仓库初始化"
        return 0
    fi
    
    print_color "blue" "📦 初始化Git仓库..."
    
    git init
    
    # 创建.gitignore
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
target/
.anchor/

# Build outputs
dist/
build/

# Test ledger
test-ledger/

# Logs
*.log
logs/

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Environment variables
.env
.env.local

# Anchor generated files
.anchor/

# Rust/Cargo
Cargo.lock
EOF

    git add .
    git commit -m "Initial commit: Created $PROJECT_NAME project"
    
    print_color "green" "✅ Git仓库初始化完成"
}

# 主创建流程
main_create() {
    local project_name=""
    local template_type="basic"
    local workspace_dir="."
    local no_git=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --template)
                template_type="$2"
                shift 2
                ;;
            --workspace)
                workspace_dir="$2"
                shift 2
                ;;
            --no-git)
                no_git=true
                shift
                ;;
            -*)
                print_color "red" "❌ 未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                project_name="$1"
                shift
                ;;
        esac
    done
    
    # 使用配置文件中的项目名称（如果未指定）
    if [ -z "$project_name" ]; then
        project_name="$PROJECT_NAME"
    fi
    
    # 验证项目名称
    if [[ ! "$project_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        print_color "red" "❌ 项目名称只能包含字母、数字和下划线，且必须以字母开头"
        exit 1
    fi
    
    # 检查必要工具
    check_tools
    
    print_color "blue" "🚀 开始创建Solana项目..."
    print_color "blue" "项目名称: $project_name"
    print_color "blue" "模板类型: $template_type"
    print_color "blue" "工作目录: $workspace_dir"
    echo ""
    
    # 检查项目目录是否已存在
    if [ -d "$workspace_dir/$project_name" ]; then
        print_color "red" "❌ 项目目录已存在: $workspace_dir/$project_name"
        echo "请选择不同的项目名称或删除现有目录"
        exit 1
    fi
    
    # 进入工作目录
    cd "$workspace_dir"
    
    # 创建项目
    create_anchor_project "$project_name" "$workspace_dir"
    
    # 创建模板文件
    create_template_files "$template_type" "$project_name"
    
    # 初始化Git仓库
    init_git "$no_git"
    
    # 安装依赖
    print_color "blue" "📦 安装项目依赖..."
    if command -v yarn &> /dev/null; then
        yarn install
    else
        npm install
    fi
    
    # 显示项目信息
    echo ""
    print_color "green" "🎉 项目创建完成！"
    echo ""
    print_color "blue" "📋 项目信息:"
    echo "项目名称: $project_name"
    echo "项目路径: $(pwd)"
    echo "模板类型: $template_type"
    echo "程序ID: $(cat target/deploy/${project_name}-keypair.json | solana address -k /dev/stdin)"
    
    echo ""
    print_color "blue" "📝 接下来的步骤："
    echo "  1. 进入项目目录: cd $project_name"
    echo "  2. 构建项目: ./scripts/build.sh"
    echo "  3. 运行测试: ./scripts/test.sh"
    echo "  4. 部署项目: ./scripts/deploy.sh devnet"
    
    echo ""
    print_color "blue" "📚 学习资源:"
    echo "  - Anchor文档: https://anchor-lang.com/"
    echo "  - Solana文档: https://docs.solana.com/"
    echo "  - 项目README: ./$project_name/README.md"
}

# 执行主流程
main_create "$@"