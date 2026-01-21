# 📚 文档导航

> 快速找到您需要的文档

## 🚀 新手必读

### 1. 快速开始
**[README.md](./README.md)** - 项目总览和 5 分钟快速上手

**内容：**
- 快速安装步骤
- 一键修复工具
- 项目结构
- 验证清单

### 2. 详细教程
**[QUICK_START.md](./QUICK_START.md)** - 零基础完整教程

**内容：**
- 环境搭建详细步骤
- 钱包设置
- 创建第一个项目
- 构建和测试
- 部署到测试网
- 常见问题解答

### 3. 中文指南
**[solana-dev-scripts/快速开始指南.md](./solana-dev-scripts/快速开始指南.md)** - 中文版快速指南

**适合：**
- 中文用户
- 喜欢中文文档的开发者

---

## 🔧 问题排查

### 故障排除
**[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - 详细的问题诊断和解决方案

**内容：**
- 根本原因分析
- 三种解决方案
- 技术细节说明
- 预防措施

### 诊断工具
**[diagnose.sh](./diagnose.sh)** - 自动诊断脚本
```bash
bash diagnose.sh
```

### 修复工具
**[final-fix.sh](./final-fix.sh)** - 一键修复工具
```bash
bash final-fix.sh
```

---

## 📖 脚本文档

### 脚本使用说明
**[solana-dev-scripts/README.md](./solana-dev-scripts/README.md)** - 脚本工具包完整说明

**内容：**
- 所有脚本列表
- 使用示例
- 配置说明
- 帮助信息

### 配置文件
**[solana-dev-scripts/config/project-config.sh](./solana-dev-scripts/config/project-config.sh)** - 统一配置文件

**可配置项：**
- 项目名称
- 开发者信息
- 网络设置
- 钱包路径

---

## 📜 历史记录

### 项目历史
**[ARCHIVE.md](./ARCHIVE.md)** - 项目完成状态和改进历史

**内容：**
- 已完成功能清单
- 重大改进记录
- 设计原则
- 技术细节

### 已弃用文档
以下文档已合并到主文档，可以忽略：
- ~~COMPLETION_SUMMARY.md~~ → 已合并到 ARCHIVE.md
- ~~NEXT_STEPS.md~~ → 已合并到 QUICK_START.md
- ~~UPDATE_SUMMARY.md~~ → 已合并到 ARCHIVE.md

---

## 🎯 使用场景

### 场景 1：第一次使用

1. 阅读 **[README.md](./README.md)**
2. 跟随步骤安装环境
3. 遇到问题查看 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**

### 场景 2：了解详细步骤

1. 阅读 **[QUICK_START.md](./QUICK_START.md)**
2. 按步骤完成环境搭建
3. 创建第一个项目

### 场景 3：遇到构建错误

1. 运行 `bash final-fix.sh`
2. 如果未解决，查看 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**
3. 运行 `bash diagnose.sh` 诊断问题

### 场景 4：了解脚本功能

1. 阅读 **[solana-dev-scripts/README.md](./solana-dev-scripts/README.md)**
2. 查看各脚本的 `--help` 选项
3. 参考示例使用

---

## 🆘 获取帮助的顺序

1. **快速查找：**
   - 查看 [README.md](./README.md) 快速上手部分

2. **常见问题：**
   - 查看 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

3. **详细教程：**
   - 阅读 [QUICK_START.md](./QUICK_START.md)

4. **脚本帮助：**
   ```bash
   bash setup/01-install-tools.sh --help
   ```

5. **自动诊断：**
   ```bash
   bash diagnose.sh
   ```

6. **一键修复：**
   ```bash
   bash final-fix.sh
   ```

---

## 📊 文档状态

| 文档 | 状态 | 用途 | 更新日期 |
|------|------|------|----------|
| README.md | ✅ 最新 | 项目总览 | 2024 |
| QUICK_START.md | ✅ 最新 | 详细教程 | 2024 |
| TROUBLESHOOTING.md | ✅ 最新 | 故障排除 | 2024 |
| ARCHIVE.md | ✅ 最新 | 历史记录 | 2024 |
| solana-dev-scripts/README.md | ✅ 最新 | 脚本说明 | 2024 |
| solana-dev-scripts/快速开始指南.md | ✅ 最新 | 中文指南 | 2024 |

---

**文档持续更新中，欢迎反馈！** 🎉
