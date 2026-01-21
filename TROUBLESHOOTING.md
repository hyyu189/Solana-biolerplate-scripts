# Solana 开发常见问题排查指南

## 问题：cargo-build-sbf SDK 路径错误

### 症状

运行 `01-install-tools.sh --check` 显示所有工具都已安装：
```
✅ Rust: 1.82.0
✅ Cargo: 1.82.0
✅ Solana CLI: 1.18.20
✅ Anchor: 0.32.1
✅ Node.js: v24.10.0
✅ Yarn: 1.22.22
```

但运行 `bash solana-dev-scripts/run-fix.sh` 或 `anchor build` 时报错：
```
[ERROR cargo_build_sbf] Solana SDK path does not exist: 
/Users/haiyangyu/.cargo/bin/sdk/sbf: No such file or directory (os error 2)
```

### 根本原因

这是一个**两阶段安装问题**：

1. **工具安装阶段**：
   - ✅ `solana-cli` 已正确安装（CLI命令）
   - ✅ `anchor` 已正确安装（框架）
   - ✅ `cargo-build-sbf` 命令已安装（编译工具）

2. **SDK 安装阶段**（缺失）：
   - ❌ **BPF SDK** 未下载（编译所需的库和工具链）
   - ❌ SDK 应该在 `~/.cache/solana/vX.X.X/sdk/sbf/` 目录
   - ❌ `cargo-build-sbf` 在首次运行时会自动下载 SDK

### 为什么会发生？

**01-install-tools.sh 只安装了命令行工具，没有触发 SDK 下载。**

SDK 的下载时机：
- ✅ 当首次运行 `cargo build-sbf --force-tools-install` 时
- ✅ 当首次运行 `anchor build` 时

但如果 `cargo-build-sbf` 工具本身有问题（版本不匹配、路径错误等），SDK 就无法正确下载。

### 解决方案

#### 方案 1：一键修复（推荐）

运行综合修复脚本：
```bash
bash solana-dev-scripts/run-fix.sh
```

这个脚本会：
1. 清理旧的 Solana 缓存
2. 从 Agave 仓库重新安装 `cargo-build-sbf` 工具
3. 强制下载并安装 BPF SDK
4. 验证安装是否成功

#### 方案 2：手动修复

```bash
# 步骤 1: 清理缓存
rm -rf ~/.cache/solana/*

# 步骤 2: 重新安装 cargo-build-sbf（从官方 Agave 仓库）
cargo install --git https://github.com/anza-xyz/agave cargo-build-sbf --locked --force

# 步骤 3: 强制安装 BPF 工具链（会自动下载 SDK，约50-100MB）
cargo build-sbf --force-tools-install

# 步骤 4: 验证
cargo-build-sbf --version
find ~/.cache/solana -name "sbf" -type d
```

#### 方案 3：使用 Anchor 触发下载

```bash
cd my_solana_project
anchor build
```

首次构建会自动下载 SDK，但前提是 `cargo-build-sbf` 工具正确安装。

### 验证修复

```bash
# 1. 检查工具版本
cargo-build-sbf --version

# 2. 检查 SDK 是否存在
find ~/.cache/solana -name "sbf" -type d

# 3. 尝试构建项目
cd my_solana_project
anchor build
```

如果看到类似输出，说明修复成功：
```
📁 /Users/haiyangyu/.cache/solana/v1.18/sdk/sbf
```

### 预防措施

**更新 01-install-tools.sh 脚本建议：**

在安装工具后，添加 SDK 预下载步骤：
```bash
# 在脚本末尾添加
echo "📦 预下载 BPF SDK..."
cargo build-sbf --force-tools-install
```

这样可以确保在工具安装阶段就完成 SDK 的下载。

### 技术细节

**Solana 工具链结构：**

```
~/.cache/solana/
├── v1.18.20/                    # Solana 版本
│   └── sdk/
│       └── sbf/                 # BPF SDK（编译目标）
│           ├── dependencies/     # 依赖库
│           ├── scripts/         # 编译脚本
│           └── c/               # C 头文件
└── v1.18.20-release/            # 发布版本工具

~/.cargo/bin/
├── solana                       # Solana CLI 命令
├── anchor                       # Anchor CLI 命令
└── cargo-build-sbf             # BPF 编译工具
```

**cargo-build-sbf 的工作流程：**
1. 检查 `~/.cache/solana/` 中是否有匹配版本的 SDK
2. 如果不存在，使用 `--force-tools-install` 自动下载
3. 使用 SDK 中的工具链编译 Rust 代码为 BPF 字节码
4. 输出 `.so` 文件（Solana 程序）

### 相关资源

- [Anchor 官方文档 - 安装故障排除](https://www.anchor-lang.com/docs/installation)
- [Agave GitHub](https://github.com/anza-xyz/agave)
- [Solana 工具安装指南](https://docs.solana.com/cli/install-solana-cli-tools)

---

## 其他常见问题

### 问题：网络连接超时

**症状：**
```
error: failed to download from GitHub
```

**解决方案：**
1. 检查网络连接
2. 配置 Git 代理（如需要）
3. 使用镜像源

### 问题：Anchor 版本不兼容

**症状：**
```
Error: anchor version X.X.X is not compatible with project version Y.Y.Y
```

**解决方案：**
```bash
# 检查项目要求的版本
cat Anchor.toml | grep anchor_version

# 安装匹配版本
avm install <version>
avm use <version>
```

### 问题：Rust 工具链错误

**症状：**
```
error: toolchain 'stable-x86_64-apple-darwin' is not installed
```

**解决方案：**
```bash
rustup update
rustup default stable
```
