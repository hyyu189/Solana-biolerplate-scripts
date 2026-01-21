# Solana 新手快速入门指南

## 📋 准备工作

### 系统要求
- **操作系统：** macOS 或 Linux
- **硬盘空间：** 至少 10GB 可用空间
- **网络：** 需要稳定的网络连接

---

## 🚀 第一步：安装开发环境

### 1.1 自动安装（推荐）

```bash
cd ~/Code/SolanaNewbie/solana-dev-scripts
bash setup/01-install-tools.sh
```

**这个脚本会自动安装：**
- ✅ Rust 开发环境
- ✅ Solana CLI 工具
- ✅ Anchor 框架
- ✅ 其他必需工具

**预计时间：** 10-20 分钟

### 1.2 安装完成后的必做步骤

**⚠️ 重要：安装完成后必须重启终端！**

或者运行以下命令之一：
```bash
source ~/.bashrc  # bash 用户
source ~/.zshrc   # zsh 用户
```

### 1.3 验证安装

```bash
bash setup/01-install-tools.sh --check
```

**预期输出：**
```
✅ Rust: 已安装
✅ Solana: 1.18.x
✅ Anchor: 0.30.x
✅ Cargo Build SBF: 已安装
```

---

## 🔑 第二步：设置钱包

### 2.1 创建新钱包

```bash
bash setup/02-setup-wallet.sh --new
```

**脚本会：**
1. 生成新的密钥对
2. 保存到 `~/.config/solana/id.json`
3. 显示您的钱包地址

**⚠️ 重要提示：**
- 妥善保管私钥文件
- 不要分享给任何人
- 建议备份到安全位置

### 2.2 获取测试代币

```bash
solana airdrop 2
```

### 2.3 查看余额

```bash
solana balance
```

---

## 📦 第三步：创建第一个项目

### 3.1 使用脚本创建项目

```bash
cd ~/Code/SolanaNewbie/solana-dev-scripts
bash project/03-create-project.sh
```

**脚本会：**
1. 创建 Anchor 项目 `my_solana_project`
2. 生成示例合约代码
3. 配置项目环境

### 3.2 查看项目结构

```bash
cd ../my_solana_project
tree -L 2
```

**项目结构：**
```
my_solana_project/
├── programs/           ← Solana 合约代码
│   └── my_solana_project/
├── tests/             ← 测试代码
├── Anchor.toml        ← Anchor 配置
├── Cargo.toml         ← Rust 包管理
└── package.json       ← Node.js 依赖
```

---

## 🔨 第四步：构建项目

### 4.1 编译合约

```bash
cd ~/Code/SolanaNewbie/my_solana_project
anchor build
```

**成功标志：**
```
✅ Build successful
✨ Compiled program: my_solana_project
```

### 4.2 查看编译产物

```bash
ls -lh target/deploy/
```

应该看到：
- `my_solana_project.so` - 编译后的程序
- `my_solana_project-keypair.json` - 程序密钥对

---

## 🧪 第五步：运行测试

### 5.1 运行所有测试

```bash
anchor test
```

**测试流程：**
1. 启动本地验证器
2. 部署合约
3. 运行测试用例
4. 显示测试结果

### 5.2 仅运行测试（跳过构建）

```bash
anchor test --skip-build
```

---

## 🚀 第六步：部署到测试网

### 6.1 切换到 Devnet

```bash
solana config set --url devnet
```

### 6.2 获取测试代币

```bash
solana airdrop 2
```

### 6.3 部署合约

```bash
bash ~/Code/SolanaNewbie/solana-dev-scripts/deployment/09-deploy-devnet.sh
```

### 6.4 验证部署

```bash
solana program show <YOUR_PROGRAM_ID>
```

---

## ❓ 常见问题

### Q1: 构建失败，提示 "SDK path does not exist"

**解决方案：**
```bash
cd ~/Code/SolanaNewbie
bash final-fix.sh
# 然后重启终端！
```

### Q2: `anchor` 命令找不到

**解决方案：**
1. 重启终端
2. 或运行：`source ~/.cargo/env`
3. 验证：`which anchor`

### Q3: 测试网没有余额

**解决方案：**
```bash
solana airdrop 2
```

如果失败，等待几分钟后重试。

### Q4: 端口被占用

**解决方案：**
```bash
pkill solana-test-validator
```

---

## 📚 下一步学习

### 学习资源

1. **官方文档：**
   - [Solana 文档](https://docs.solana.com/)
   - [Anchor 文档](https://www.anchor-lang.com/)

2. **示例项目：**
   - [Anchor Examples](https://github.com/coral-xyz/anchor/tree/master/examples)

3. **教程：**
   - 修改 `programs/my_solana_project/src/lib.rs`
   - 添加新的指令
   - 实现自己的业务逻辑

### 实践建议

1. ✅ **先完成环境搭建**（您已完成）
2. 📖 **阅读 Anchor 官方教程**
3. 🔧 **修改示例项目**
4. 🧪 **编写测试用例**
5. 🚀 **部署到测试网**
6. 💡 **开发自己的 DApp**

---

## 🆘 获取帮助

### 遇到问题？

1. **查看故障排除文档：**
   ```bash
   cat ~/Code/SolanaNewbie/TROUBLESHOOTING.md
   ```

2. **运行诊断脚本：**
   ```bash
   bash ~/Code/SolanaNewbie/diagnose.sh
   ```

3. **查看脚本帮助：**
   ```bash
   bash setup/01-install-tools.sh --help
   ```

---

**祝您学习愉快！** 🎉

有任何问题，请查看 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) 或提交 Issue。
