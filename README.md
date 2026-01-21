# Solana 开发脚本工具包

> 为 Solana 初学者设计的一站式开发工具

## ⚡ 快速导航

- **[快速开始指南](./快速开始指南.md)** - 初学者必读
- **[项目配置](./config/project-config.sh)** - 统一配置文件

## 📁 核心脚本（10/10 ✅）

### 环境配置
| 脚本 | 功能 | 使用 |
|------|------|------|
| `setup/01-install-tools.sh` | 安装 Rust、Solana、Anchor | `bash setup/01-install-tools.sh` |
| `setup/02-setup-wallet.sh` | 创建/导入钱包，获取测试币 | `bash setup/02-setup-wallet.sh --new` |

### 项目管理
| 脚本 | 功能 | 使用 |
|------|------|------|
| `project/03-create-project.sh` | 创建 Anchor 项目 | `bash project/03-create-project.sh` |
| `project/04-setup-environment.sh` | 配置项目环境 | `bash project/04-setup-environment.sh` |

### 开发工具
| 脚本 | 功能 | 使用 |
|------|------|------|
| `development/05-build.sh` | 编译合约 | `bash development/05-build.sh` |
| `development/06-test.sh` | 运行测试 | `bash development/06-test.sh` |
| `development/07-clean.sh` | 清理构建产物 | `bash development/07-clean.sh` |

### 部署运维
| 脚本 | 功能 | 使用 |
|------|------|------|
| `deployment/08-deploy-local.sh` | 本地部署 | `bash deployment/08-deploy-local.sh` |
| `deployment/09-deploy-devnet.sh` | 测试网部署 | `bash deployment/09-deploy-devnet.sh` |
| `deployment/10-monitor.sh` | 程序监控 | `bash deployment/10-monitor.sh --all` |

### 修复工具
| 脚本 | 功能 | 使用 |
|------|------|------|
| `repair-tools.sh` | 一键诊断和修复 | `bash repair-tools.sh` |

## 🚀 快速开始

### 步骤 1: 配置项目信息

首先编辑 `config/project-config.sh` 文件，填入你的项目信息：

```bash
# 编辑配置文件
nano config/project-config.sh
```

### 步骤 2: 运行安装脚本

```bash
# 安装开发工具
./setup/01-install-tools.sh

# 配置钱包
./setup/02-setup-wallet.sh
```

### 步骤 3: 创建项目

```bash
# 创建新项目
./project/03-create-project.sh

# 设置项目环境
./project/04-setup-environment.sh
```

### 步骤 4: 开发和测试

```bash
# 构建程序
./development/05-build.sh

# 运行测试
./development/06-test.sh
```

### 步骤 5: 部署

```bash
# 本地部署测试
./deployment/08-deploy-local.sh

# 部署到开发网
./deployment/09-deploy-devnet.sh
```

## ⚙️ 配置说明

所有脚本都会读取 `config/project-config.sh` 中的配置。你只需要修改这一个文件即可。

## 📞 获取帮助

每个脚本都支持 `--help` 参数查看详细说明：

```bash
./setup/01-install-tools.sh --help
```

## 🔧 故障排除

### 🚑 一键修复工具（推荐）

遇到任何环境问题？使用我们的智能修复工具：

```bash
# 自动诊断并修复所有问题
bash repair-tools.sh

# 仅检查问题
bash repair-tools.sh --check

# 完整重新安装
bash repair-tools.sh --full
```

修复工具会自动：
- 🔍 诊断5类常见问题
- 🔧 修复 BPF SDK 路径错误
- ✅ 验证修复结果
- 📝 提供下一步建议

### 常见问题速查

#### 1. 构建失败："SDK path does not exist"

最常见的问题，运行：
```bash
bash repair-tools.sh
```

#### 2. 检查工具安装状态

```bash
./setup/01-install-tools.sh --check
```

#### 3. 网络连接问题

- 检查网络连接
- 配置代理（如需要）
- 查看日志: `/tmp/repair-*.log`

### 详细文档

更多问题诊断和解决方案：
📘 **[TROUBLESHOOTING.md](../TROUBLESHOOTING.md)**